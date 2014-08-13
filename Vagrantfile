#!/env/ruby
# -*- mode: ruby -*-
# vi: set ft=ruby :

#######################################
# EDIT SETTINGS HERE
#######################################
# docker base image name
base_image_name = "vagrant-baseimage"
# docker / vagrant hostname
hostname = "vagrant-docker-container"
# guest -> host mapping of ports
ports = {22 => 2222, 80 => 8080}
# gets the current user
current_user = "#{ENV['USER']}"
# The timezone the machine should live in
timezone = "Europe/Berlin"

# determine the current provider ... somehow
provider = (ARGV[2] || ENV['VAGRANT_DEFAULT_PROVIDER'] || :virtualbox).to_sym

Vagrant.configure("2") do |config|

    ###################################
    # DEFINE VM FOR VIRTUAL BOX
    ###################################
    config.vm.define :"#{hostname}" do |cfg|
        cfg.vm.provision :shell,
            path:       "./vbox.sh",
            privileged: true,
            args:       ["#{hostname}", ports.keys.join(','), "#{base_image_name}"]
    end

    ###################################
    # CONFIGURE VIRTUAL BOX
    ###################################
    config.vm.provider :virtualbox do |v, config|
        if provider == :virtualbox
            ports.each do |guestport, hostport|
                if guestport != 22
                    config.vm.network "forwarded_port",
                        guest:        guestport,
                        host:         hostport,
                        auto_correct: true
                end
            end
        end
        
        config.vm.box     = 'trusty64'
        config.vm.box_url = 'https://cloud-images.ubuntu.com/vagrant/trusty/current/trusty-server-cloudimg-amd64-vagrant-disk1.box'

        v.customize ["setextradata", :id, "VBoxInternal2/SharedFoldersEnableSymlinksCreate/v-root", "1"]
        v.customize ["modifyvm",     :id, "--memory", 1024]
        v.customize ["modifyvm",     :id, "--cpus", 2]
        v.customize ["modifyvm",     :id, "--hwvirtex", "on"]
        v.customize ["modifyvm",     :id, "--nestedpaging", "on"]
    end

    ###################################
    # CONFIGURE DOCKER
    ###################################
    config.vm.provider :docker do |d|
    
        if provider == :docker
            config.ssh.username         = "root"
            config.ssh.private_key_path = "./id_rsa_vagrant"
    
            ssh_key_file = `echo -n \`pwd\`` + "/id_rsa_vagrant"
            if !File.file?(ssh_key_file)
                `ssh-keygen -b 2048 -t rsa -f #{ssh_key_file} -q -N ''`
            end
        end

        d.build_dir                 = "."
        d.build_args                = [
                                          "--rm=true",
                                          "--force-rm=true",
                                          "--tag=#{base_image_name}"
                                      ]
        d.has_ssh                   = true
        d.name                      = "#{hostname}"
        d.create_args               = [
                                          "--cpuset='0-1'",
                                          "--hostname='#{hostname}'",
                                          "--memory='1024m'",
                                          "--privileged=true",
                                          "--workdir='/vagrant/'",
                                          "--volume='/etc/localtime:/etc/localtime:ro'"
                                      ]
        d.env                       = {
                                          "TZ" => "#{timezone}"
                                      }
        d.host_vm_build_dir_options = {
                                          "owner" => "root",
                                          "group" => "root"
                                      }
        d.expose                    = ports.keys
    end

end
