require_relative 'cm_api'

CLUSTER = "prod001"

cm_api = CMApi.new("admin", "admin", "ec2-54-241-68-227.us-west-1.compute.amazonaws.com")
pp cm_api.get('/hosts')

# Create new cluster
cm_api.create_cluster(CLUSTER, "CDH4")

# Create a service
cm_api.create_service(CLUSTER, "hdfs001", "HDFS")

# Create hosts
HOSTNAMES = [
  ["ip-10-171-90-235.us-west-1.compute.internal", "10.171.90.235"],
  ["ip-10-174-106-221.us-west-1.compute.internal", "10.174.106.221"],
  ["ip-10-170-215-48.us-west-1.compute.internal", "10.170.215.48"]
]

HOSTNAMES.each do |host|
  cm_api.create_host(
    host[0],  # hostid
    host[0],  # host name (fqdn)
    host[1]   # ip address
  )
end

# Install cloudera manager agents on hosts
hosts = [] # hosts to install cm agents on
HOSTNAMES.each do |host|
  hosts << host[0]
end
cmd_ids = cm_api.install_cm_agent("root", hosts, :privateKey => File.expand_path('~/.ssh/ankus'))
cmd_ids.each do |cmd|
  cm_api.command_status(cmd)
end  

# Download, Distribute and Activate Parcels - CDH
available_parcels = list_available_parcels(CLUSTER) # => {"IMPALA"=>"1.2.3-1.p0.97", "SOLR"=>"1.1.0-1.cdh4.3.0.p0.21", "CDH"=>"4.5.0-1.cdh4.5.0.p0.30"}
start_parcel_download(CLUSTER, 'CDH', available_parcels['CDH'])
distribute_parcel(CLUSTER, 'CDH', available_parcels['CDH'])
activate_parcel(CLUSTER, 'CDH', available_parcels['CDH'])

# Create roles for servers
cm_api.create_role(CLUSTER, "hdfs001", "hdfs001-nn", "NAMENODE", HOSTNAMES[0][0])
cm_api.create_role(CLUSTER, "hdfs001", "hdfs001-snn", "SECONDARYNAMENODE", HOSTNAMES[0][0])
HOSTNAMES.each_with_index do |host, index|
  cm_api.create_role(CLUSTER, "hdfs001", "hdfs001-dn#{index+1}", "DATANODE", host[0])
end

# Update config for the several hdfs roles
hdfs_service_config = {
  'dfs_replication' => '1'
}
nn_config = {
  'dfs_name_dir_list' => '/dfs/nn',
  'dfs_namenode_handler_count' => '30'
}
snn_config = {
  'fs_checkpoint_dir_list' => '/dfs/snn'
}
dn_config = {
  'dfs_data_dir_list' => '/dfs/dn1,/dfs/dn2,/dfs/dn3',
  'dfs_datanode_failed_volumes_tolerated' => '1',  
}
cm_api.update_service_config(CLUSTER, "hdfs001", hdfs_service_config)
cm_api.update_role_config(CLUSTER, "hdfs001", "hdfs001-nn", nn_config)
cm_api.update_role_config(CLUSTER, "hdfs001", "hdfs001-snn", snn_config)
HOSTNAMES.each_with_index do |host, index|
  cm_api.update_role_config(CLUSTER, "hdfs001", "hdfs001-dn#{index+1}", dn_config)
end

# Format hdfs
cmd_id = cm_api.format_hdfs(CLUSTER, "hdfs001", "hdfs001-nn")
cm_api.command_status(cmd_id)

# Start hdfs
hdfs_roles = ["hdfs001-nn", "hdfs001-snn"]
HOSTNAMES.each_with_index do |host, index|
  hdfs_roles << "hdfs001-dn#{index+1}"
end  
cmd_ids = cm_api.start_service(CLUSTER, "hdfs001", hdfs_roles)
cmd_ids.each do |cmd|
  cm_api.command_status(cmd)
end