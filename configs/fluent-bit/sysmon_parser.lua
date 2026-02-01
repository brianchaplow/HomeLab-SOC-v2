-- Sysmon Event Parser for Fluent Bit
-- Location: C:\Program Files\fluent-bit\conf\sysmon_parser.lua
-- Extracts key fields from Sysmon events for better searchability

function parse_sysmon(tag, timestamp, record)
    -- Get EventID if present
    local event_id = record["EventID"]
    
    if event_id == nil then
        return 0, timestamp, record
    end
    
    -- Extract EventData fields if present
    local event_data = record["EventData"]
    
    if event_data == nil then
        return 0, timestamp, record
    end
    
    -- Event ID 1: Process Creation
    if event_id == 1 then
        record["sysmon_event_type"] = "ProcessCreate"
        record["process_name"] = event_data["Image"]
        record["command_line"] = event_data["CommandLine"]
        record["parent_process"] = event_data["ParentImage"]
        record["parent_command_line"] = event_data["ParentCommandLine"]
        record["user"] = event_data["User"]
        record["process_id"] = event_data["ProcessId"]
        record["parent_process_id"] = event_data["ParentProcessId"]
        record["hashes"] = event_data["Hashes"]
    
    -- Event ID 3: Network Connection
    elseif event_id == 3 then
        record["sysmon_event_type"] = "NetworkConnect"
        record["process_name"] = event_data["Image"]
        record["user"] = event_data["User"]
        record["dest_ip"] = event_data["DestinationIp"]
        record["dest_port"] = event_data["DestinationPort"]
        record["dest_hostname"] = event_data["DestinationHostname"]
        record["src_ip"] = event_data["SourceIp"]
        record["src_port"] = event_data["SourcePort"]
        record["protocol"] = event_data["Protocol"]
    
    -- Event ID 7: Image Loaded (DLL)
    elseif event_id == 7 then
        record["sysmon_event_type"] = "ImageLoad"
        record["process_name"] = event_data["Image"]
        record["loaded_image"] = event_data["ImageLoaded"]
        record["signed"] = event_data["Signed"]
        record["signature"] = event_data["Signature"]
        record["hashes"] = event_data["Hashes"]
    
    -- Event ID 8: CreateRemoteThread
    elseif event_id == 8 then
        record["sysmon_event_type"] = "CreateRemoteThread"
        record["source_process"] = event_data["SourceImage"]
        record["target_process"] = event_data["TargetImage"]
        record["start_address"] = event_data["StartAddress"]
        record["start_module"] = event_data["StartModule"]
        record["start_function"] = event_data["StartFunction"]
    
    -- Event ID 10: Process Access
    elseif event_id == 10 then
        record["sysmon_event_type"] = "ProcessAccess"
        record["source_process"] = event_data["SourceImage"]
        record["target_process"] = event_data["TargetImage"]
        record["granted_access"] = event_data["GrantedAccess"]
        record["call_trace"] = event_data["CallTrace"]
    
    -- Event ID 11: File Created
    elseif event_id == 11 then
        record["sysmon_event_type"] = "FileCreate"
        record["process_name"] = event_data["Image"]
        record["target_filename"] = event_data["TargetFilename"]
        record["creation_time"] = event_data["CreationUtcTime"]
    
    -- Event ID 12/13/14: Registry Events
    elseif event_id == 12 or event_id == 13 or event_id == 14 then
        record["sysmon_event_type"] = "RegistryEvent"
        record["process_name"] = event_data["Image"]
        record["target_object"] = event_data["TargetObject"]
        record["event_type"] = event_data["EventType"]
        if event_id == 13 then
            record["details"] = event_data["Details"]
        end
    
    -- Event ID 15: FileCreateStreamHash
    elseif event_id == 15 then
        record["sysmon_event_type"] = "FileCreateStreamHash"
        record["process_name"] = event_data["Image"]
        record["target_filename"] = event_data["TargetFilename"]
        record["hashes"] = event_data["Hash"]
    
    -- Event ID 22: DNS Query
    elseif event_id == 22 then
        record["sysmon_event_type"] = "DNSQuery"
        record["process_name"] = event_data["Image"]
        record["query_name"] = event_data["QueryName"]
        record["query_status"] = event_data["QueryStatus"]
        record["query_results"] = event_data["QueryResults"]
    
    -- Event ID 23: File Delete
    elseif event_id == 23 then
        record["sysmon_event_type"] = "FileDelete"
        record["process_name"] = event_data["Image"]
        record["target_filename"] = event_data["TargetFilename"]
        record["user"] = event_data["User"]
        record["hashes"] = event_data["Hashes"]
    end
    
    return 1, timestamp, record
end
