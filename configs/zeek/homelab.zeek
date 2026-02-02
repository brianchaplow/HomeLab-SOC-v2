# HomeLab SOC - Zeek live capture configuration
# Loaded after 'local' (default scripts) via: zeek -i eth4 -C local /opt/zeek/homelab.zeek

# JSON log output for Fluent Bit ingestion into OpenSearch
@load policy/tuning/json-logs

# Define local networks for proper internal/external classification
redef Site::local_nets += {
    10.10.10.0/24,     # VLAN 10 - Management
    10.10.20.0/24,     # VLAN 20 - SOC
    10.10.30.0/24,     # VLAN 30 - Lab
    10.10.40.0/24,     # VLAN 40 - Targets
    10.10.50.0/24,     # VLAN 50 - IoT
    192.168.50.0/24,   # Family LAN
    192.168.100.0/24,  # Family DMZ
};

# Rotate logs daily (keeps files manageable; 17TB available, no cleanup needed)
redef Log::default_rotation_interval = 24 hr;
