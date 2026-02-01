# Machine Learning Threat Detection

This document describes the ML-based threat scoring system integrated into the HomeLab SOC v2 automation pipeline.

---

## Overview

The ML scorer (`ml_scorer.py`) provides automated threat classification for web traffic, complementing traditional rule-based detection (Suricata) and reputation lookups (AbuseIPDB). It analyzes behavioral patterns in Apache access logs to identify potentially malicious requests.

**Key Benefits:**
- Detects novel attack patterns not covered by signatures
- Reduces false positives from reputation-only scoring
- Provides explainable predictions via SHAP values
- Runs alongside existing enrichment pipeline

---

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                     Request Flow                                 │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│   Apache Logs ──► Fluent Bit ──► OpenSearch (apache-parsed-v2)  │
│                                        │                         │
│                                        ▼                         │
│                              ┌─────────────────┐                │
│                              │  enrichment.py  │                │
│                              │                 │                │
│                              │  1. AbuseIPDB   │                │
│                              │  2. ML Scorer ◄─┼── ml_scorer.py │
│                              │  3. Whitelist   │                │
│                              └────────┬────────┘                │
│                                       │                          │
│                                       ▼                          │
│                              threat_intel.ml_score               │
│                              threat_intel.ml_verdict             │
│                              threat_intel.ml_features            │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

---

## Model Details

| Attribute | Value |
|-----------|-------|
| **Algorithm** | XGBoost Classifier |
| **Task** | Binary classification (malicious vs benign) |
| **Training Data** | Ground truth labeled requests from honeypot + legitimate traffic |
| **Output** | Probability score (0.0 - 1.0) |
| **Threshold** | 0.7 (configurable) |

### Model Files

Production models are stored at:
```
/share/Container/soc-automation/models/<model_version>/
├── model.json          # XGBoost model (JSON format)
├── feature_engineer.pkl # Scikit-learn feature transformer
└── metadata.json       # Training metadata, metrics, feature list
```

**Note:** Model files are excluded from the Git repository due to size and sensitivity. See `models/README.md` for details.

---

## Feature Engineering

The model uses behavioral and temporal features extracted from Apache access logs. Features are designed to capture attack patterns without relying on Suricata alert metadata (which would cause data leakage).

### Feature Categories

#### Request Characteristics
| Feature | Description |
|---------|-------------|
| `path_length` | Length of request path |
| `path_depth` | Directory depth (slash count) |
| `query_param_count` | Number of query parameters |
| `query_length` | Total query string length |
| `has_encoded_chars` | URL-encoded characters present |
| `has_suspicious_extension` | .php, .asp, .jsp, etc. |
| `path_entropy` | Shannon entropy of path string |

#### Behavioral Patterns
| Feature | Description |
|---------|-------------|
| `requests_per_minute` | Request rate from IP |
| `unique_paths_ratio` | Path diversity (scanning indicator) |
| `error_rate` | 4xx/5xx response ratio |
| `avg_response_size` | Mean bytes transferred |
| `method_distribution` | GET/POST/other ratios |

#### Temporal Features
| Feature | Description |
|---------|-------------|
| `hour_of_day` | Request hour (0-23) |
| `is_business_hours` | 9am-5pm ET flag |
| `request_interval_std` | Timing regularity (bot indicator) |

#### User Agent Analysis
| Feature | Description |
|---------|-------------|
| `ua_length` | User agent string length |
| `ua_has_version` | Contains version numbers |
| `ua_is_known_bot` | Matches known bot patterns |
| `ua_is_empty` | Missing or empty UA |

### Feature Engineering Pipeline

```python
# Simplified feature extraction flow
class FeatureEngineer:
    def transform(self, request_data):
        features = {}
        
        # Path analysis
        features['path_length'] = len(request_data['path'])
        features['path_depth'] = request_data['path'].count('/')
        features['path_entropy'] = self._calculate_entropy(request_data['path'])
        
        # Query analysis
        query = request_data.get('query_string', '')
        features['query_param_count'] = len(parse_qs(query))
        features['has_encoded_chars'] = '%' in query
        
        # Behavioral (requires aggregation window)
        features['requests_per_minute'] = self._get_request_rate(request_data['client_ip'])
        
        return features
```

---

## Training Pipeline

Training is performed on the Kali system (`sear`) at `/home/butcher/soc-ml/`.

### Directory Structure

```
/home/butcher/soc-ml/
├── notebooks/
│   ├── 01_data_exploration.ipynb
│   ├── 02_feature_engineering.ipynb
│   ├── 03_model_training.ipynb
│   └── 04_evaluation.ipynb
├── src/
│   ├── data_loader.py
│   ├── feature_engineer.py
│   ├── trainer.py
│   └── evaluate.py
├── data/
│   ├── raw/                    # Exported from OpenSearch
│   ├── processed/              # Feature-engineered datasets
│   └── ground_truth/           # Labeled samples
├── models/                     # Trained model outputs
└── requirements.txt
```

### Training Process

1. **Data Export:** Pull labeled data from OpenSearch
   ```bash
   python src/data_loader.py --index apache-parsed-v2 --output data/raw/
   ```

2. **Ground Truth Labeling:** 
   - Honeypot credential submissions → malicious
   - Known scanner IPs (AbuseIPDB ≥90) → malicious  
   - Legitimate visitor fingerprints → benign
   - Manual review for edge cases

3. **Feature Engineering:**
   ```bash
   python src/feature_engineer.py --input data/raw/ --output data/processed/
   ```

4. **Model Training:**
   ```bash
   python src/trainer.py \
       --data data/processed/features.parquet \
       --output models/ground_truth_v2_xgb_$(date +%Y%m%d_%H%M%S)/
   ```

5. **Evaluation:**
   ```bash
   python src/evaluate.py --model models/latest/ --test-data data/processed/test.parquet
   ```

### Avoiding Data Leakage

**Critical:** The model must NOT use features derived from Suricata alerts or AbuseIPDB scores, as these are the very things we're trying to predict/complement.

**Excluded fields:**
- `alert.signature_id`
- `alert.severity`
- `threat_intel.abuseipdb.score`
- `threat_intel.blocked`

The model should learn from request characteristics alone, not from downstream detection results.

---

## Production Deployment

### Deploying a New Model

1. **Copy model files to QNAP:**
   ```bash
   # From Kali (sear)
   scp -r models/ground_truth_v2_xgb_20260127_171501/ \
       bchaplow@10.10.20.10:/share/Container/soc-automation/models/
   ```

2. **Update config.yaml:**
   ```yaml
   ml_scoring:
     enabled: true
     model_path: "/app/models/ground_truth_v2_xgb_20260127_171501"
     threshold: 0.7
     batch_size: 100
   ```

3. **Restart soc-automation container:**
   ```bash
   ssh -p 2222 bchaplow@10.10.20.10
   docker restart soc-automation
   ```

4. **Verify scoring:**
   ```bash
   docker exec soc-automation python scripts/ml_scorer.py --test
   ```

### Model Versioning

Models follow the naming convention:
```
<training_data>_<algorithm>_<timestamp>/
```

Examples:
- `ground_truth_v1_xgb_20260115_140322/` - Initial model
- `ground_truth_v2_xgb_20260127_171501/` - After leakage fix
- `honeypot_rf_20260201_093000/` - Random Forest experiment

---

## Integration with Enrichment Pipeline

The ML scorer is called from `enrichment.py` after AbuseIPDB lookup:

```python
# In enrichment.py
from ml_scorer import MLScorer

scorer = MLScorer(model_path=config['ml_scoring']['model_path'])

def enrich_request(request):
    # 1. AbuseIPDB lookup
    abuse_data = abuse_client.check_ip(request['client_ip'])
    
    # 2. ML scoring
    ml_result = scorer.score(request)
    
    # 3. Combined verdict
    request['threat_intel'] = {
        'abuseipdb': abuse_data,
        'ml_score': ml_result['probability'],
        'ml_verdict': ml_result['verdict'],
        'ml_features': ml_result['top_features'],  # SHAP explanations
    }
    
    return request
```

### OpenSearch Field Mapping

| Field | Type | Description |
|-------|------|-------------|
| `threat_intel.ml_score` | float | Probability (0.0-1.0) |
| `threat_intel.ml_verdict` | keyword | "malicious", "suspicious", "benign" |
| `threat_intel.ml_features` | object | Top contributing features |
| `threat_intel.ml_model_version` | keyword | Model identifier |

### Verdict Thresholds

| Score Range | Verdict | Action |
|-------------|---------|--------|
| ≥ 0.85 | malicious | Alert + consider blocking |
| 0.70 - 0.84 | suspicious | Flag for review |
| < 0.70 | benign | No action |

---

## Performance Metrics

### Current Model (ground_truth_v2)

| Metric | Value |
|--------|-------|
| **PR-AUC** | 0.73 |
| **Precision @ 0.7** | 0.81 |
| **Recall @ 0.7** | 0.68 |
| **F1 Score** | 0.74 |

### Confusion Matrix (Test Set)

```
                 Predicted
              Benign  Malicious
Actual Benign   847      43
    Malicious    62     148
```

### Top Features (by SHAP importance)

1. `path_entropy` - High entropy indicates encoded payloads
2. `requests_per_minute` - Automated scanning behavior
3. `query_param_count` - Injection attempts often have many params
4. `ua_is_empty` - Missing UA common in scripts/bots
5. `has_encoded_chars` - URL encoding for evasion

---

## Monitoring & Retraining

### Dashboard Queries

**ML Score Distribution:**
```json
GET apache-parsed-v2/_search
{
  "size": 0,
  "aggs": {
    "ml_score_histogram": {
      "histogram": {
        "field": "threat_intel.ml_score",
        "interval": 0.1
      }
    }
  }
}
```

**High ML Score, Low AbuseIPDB (novel threats):**
```json
GET apache-parsed-v2/_search
{
  "query": {
    "bool": {
      "must": [
        { "range": { "threat_intel.ml_score": { "gte": 0.8 } } },
        { "range": { "threat_intel.abuseipdb.score": { "lt": 50 } } }
      ]
    }
  }
}
```

### Retraining Triggers

Consider retraining when:
- Precision drops below 0.75 on recent data
- New attack patterns emerge (check honeypot)
- Significant traffic pattern changes
- Monthly scheduled refresh

---

## Future Improvements

### Planned
- [ ] Add request body analysis for POST requests
- [ ] Implement online learning for drift adaptation
- [ ] Add ensemble with Isolation Forest for anomaly detection
- [ ] Geographic features from Cloudflare headers

### Experimental
- [ ] Deep learning on raw request sequences
- [ ] Graph-based analysis of IP relationships
- [ ] LLM-assisted ground truth labeling

---

## References

- [XGBoost Documentation](https://xgboost.readthedocs.io/)
- [SHAP Values Explained](https://shap.readthedocs.io/)
- [Avoiding Data Leakage in ML](https://machinelearningmastery.com/data-leakage-machine-learning/)
- [HomeLab SOC v2 Architecture](architecture.md)

---

*Last updated: January 2026*
