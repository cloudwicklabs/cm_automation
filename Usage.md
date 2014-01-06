#CM Automation

##Automating Cloudera Manager Installation using Chef
###Installing Chef Server
On the machine you want to install chef server run the following command

```
curl https://raw.github.com/ashrithr/scripts/master/chef_installer.sh | bash /dev/stdin -s
```

Once chef server is up and running, run `knife configure -i` to configure knife tool.

> For RedHat based installations, use `source ~/.bash_profile` to load chef path before running knife.

Sample knife initialization (*On CentOS*):

```
$knife configure -i
WARNING: No knife configuration file found
Where should I put the config file? [/root/.chef/knife.rb]
Please enter the chef server URL: [http://ip-10-251-35-221.us-west-2.compute.internal:4000] https://ip-10-251-35-221.us-west-2.compute.internal
Please enter a name for the new user: [root]
Please enter the existing admin name: [admin] chef-webui
Please enter the location of the existing admin's private key: [/etc/chef/admin.pem] ~/.chef/chef-webui.pem
Please enter the validation clientname: [chef-validator]
Please enter the location of the validation key: [/etc/chef/validation.pem] ~/.chef/chef-validator.pem
Please enter the path to a chef repository (or leave blank):
Creating initial API user...
Please enter a password for the new user:
Created user[root]
Configuration file written to /root/.chef/knife.rb
```

Sample knife initialization (*On Ubuntu*):

```
knife configure -i
WARNING: No knife configuration file found
Where should I put the config file? [/root/.chef/knife.rb] 
Please enter the chef server URL: [http://ip-10-197-54-125.us-west-1.compute.internal:4000] 
Please enter a clientname for the new client: [ubuntu] 
Please enter the existing admin clientname: [chef-webui] 
Please enter the location of the existing admin client's private key: [/etc/chef/webui.pem] ~/.chef/webui.pem
Please enter the validation clientname: [chef-validator]  
Please enter the location of the validation key: [/etc/chef/validation.pem] ~/.chef/validation.pem
Please enter the path to a chef repository (or leave blank): 
Creating initial API user...
Created client[ubuntu]
Configuration file written to /root/.chef/knife.rb
```


Verfiy chef setup using 

```
knife client list
```

###Download required cookbooks
Get the `java` and `scm` cookbooks

```
git clone https://github.com/cloudwicklabs/cm_automation.git
```

Install dependency cookbooks:

```
knife cookbook site install apt -o cm_automation/chef/cookbooks
knife cookbook site install yum -o cm_automation/chef/cookbooks
```

Upload all the cookbooks to chef server:

```
knife cookbook upload -o cm_automation/chef/cookbooks --all
```

Also, upload required roles:

```
knife role from file cm_automation/chef/roles/*.rb
```

###Bootstraping chef agents
To install chef agents on the machines that you want to manage use `knife bootstrap`.

Assign roles to the nodes before bootstraping them:

1. Add `cmserver` role to chef server (ex: cs.cw.com):

    ```
    knife bootstrap cs.cw.com -i ~/.ssh/ankus -x root -r "role[cmserver]"
    ```

2. Bootsrap `cmagent` roles on agents (ex: ca[1-5].cw.com):

    ```
    knife bootstrap ca1.cw.com -i ~/.ssh/ankus -x root -r "role[cmagent]"
    knife bootstrap ca2.cw.com -i ~/.ssh/ankus -x root -r "role[cmagent]"
    knife bootstrap ca3.cw.com -i ~/.ssh/ankus -x root -r "role[cmagent]"
    knife bootstrap ca4.cw.com -i ~/.ssh/ankus -x root -r "role[cmagent]"
    knife bootstrap ca5.cw.com -i ~/.ssh/ankus -x root -r "role[cmagent]"
    ```

> Verify the nodes in the cm console @ http://${cmserver}:7180

##Automating Cloudera Manager Installation using Puppet
###Installing Puppet Server
On the machine you want to install puppet server run the following command:

```
curl https://raw.github.com/ashrithr/scripts/master/puppetinstaller.sh | bash /dev/stdin -s
```

###Installing Puppet Agents
On the machines you want to install puppet agents run the following command, replace the SERVER_NAME with your puppet server's fqdn:

```
curl https://raw.github.com/ashrithr/scripts/master/puppetinstaller.sh | bash /dev/stdin -c -H SERVER_NAME
```

###Downloading required puppet modules
Download `java` and `scm` puppet modules on the puppet server:

```
git clone https://github.com/cloudwicklabs/cm_automation.git
cp -r cm_automation/puppet/modules/java /etc/puppet/modules/
cp -r cm_automation/puppet/modules/scm /etc/puppet/modules/
```

Install dependency modules:

```
puppet module install puppetlabs-apt
```

###Setup Node Definitions
Now, define nodes (`/etc/puppet/manifests/site.pp`):


```puppet
node 'cs.cw.com' {
    include scm::server
}

node /^ca(\d+)\.cw\.com$/ {
    class { 'scm::agent':
        server_host => 'cs.cw.com'
    }
}
```

Run puppet on all the nodes to get configuration updated

##Deploy Cluster using cm_api
See `cm_api_ruby/example.rb` for usage