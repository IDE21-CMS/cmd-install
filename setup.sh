#!/bin/bash
echo 'IDE21 install script starting...';
if [ -d "./IDE21" ]; then
    echo "IDE21 folder exists. Do you wish to update configuration? (y/n)"
    read update_configuration;
    if [[ $update_configuration == "y" ]]; then
        echo 'Updating existing configuration...';
    else
        echo 'No changes to current configuration.';
        exit 0;
    fi

else
    echo "IDE21 folder does not exist, cloning it"
    git clone https://github.com/nebojsatomic/IDE21.git

    echo "Do you wish to create self-signed certificates? If NO, you will need to have cert.pem and key.pem files already present in apache2 folder ( y/n )";
    read create_certs;

    if [[ $create_certs == "n" ]]; then
        if [[ -f "./SETUP_FILES/apache2/cert.pem" && -f "./SETUP_FILES/apache2/key.pem" ]]; then
            echo "Cert and key files exist, proceeding..."
        else
            echo 'Please provide .pem files in apache2 folder, and start setup.sh again.';
            exit 1;
        fi
    else
        echo "Creating self-signed certificates : ";
        # if files already exist, need to change file permissions first
        if [[ -f "./SETUP_FILES/apache2/cert.pem" && -f "./SETUP_FILES/apache2/key.pem" ]]; then
            chmod 666 ./SETUP_FILES/apache2/cert.pem;
            chmod 666 ./SETUP_FILES/apache2/key.pem;
        fi
        # then generate new key and cert files
        openssl req -newkey rsa:4096 -new -nodes -x509 -days 3650 -keyout ./SETUP_FILES/apache2/key.pem -out ./SETUP_FILES/apache2/cert.pem
        # set file permissions again to less permissive
        chmod 444 ./SETUP_FILES/apache2/cert.pem;
        chmod 444 ./SETUP_FILES/apache2/key.pem;
    fi

    echo 'Copying certificate files';
    cp -r ./SETUP_FILES/apache2 ./IDE21
    echo 'Done.';


    echo 'Enter your variables here:';
    echo 'Enter your domain name:';
    read your_domain_name;

    # Admin area variables
    echo 'Enter your Admin url:';
    read your_admin_url;

    echo 'Enter your Admin username:';
    read your_admin_username;

    echo 'Enter your Admin password:';
    read your_admin_password;

    # Database variables
    echo 'Enter your Database username:';
    read your_database_username;

    echo 'Enter your Database password:';
    read your_database_password;

    echo 'Enter your Database name:';
    read your_database_name;

    echo 'Do you wish to setup SMTP mail configuration? (y/n)';
    read setup_mail;

    if [[ $setup_mail == "y" ]]; then
        echo 'Setting up mail configuration';
    else
        echo 'SMTP configuration not set.';
    fi

    #echo "domain name: $your_domain_name, admin url: $your_admin_url, database username: $your_database_username, DatabasePassword: $your_database_password, Database Name: $your_database_name";

    sed -i "s/{YOUR_DOMAIN_NAME}/${your_domain_name}/g;s/{YOUR_ADMIN_URL}/${your_admin_url}/g;s/{YOUR_DATABASE_USERNAME}/${your_database_username}/g;s/{YOUR_DATABASE_PASSWORD}/${your_database_password}/g;s/{YOUR_DATABASE_NAME}/${your_database_name}/g" ./SETUP_FILES/src/legacy/dev-application/config/config.ini

    echo 'Copying config file';
    cp -r ./SETUP_FILES/src ./IDE21
    echo 'Done.';

    echo 'Copying docker-compose.yaml';
    cp ./SETUP_FILES/docker-compose.yaml ./IDE21
    echo 'Done.';

    cd IDE21
    echo 'Entered IDE21 folder';
    #cat src/legacy/dev-application/config/config.ini
    #cat docker-compose.yaml

    echo 'Starting docker image build...'
    docker ps -a;
    docker compose down -v;
    docker rmi web:latest;
    docker compose up -d;

    echo 'Please wait...'
    sleep 15;

    docker ps;
    container_id=$(docker ps -aqf "name=ide21-mysqldb");


    docker exec --user=root -it $container_id bash -c 'mysql -u root -pnebojsa -sNe "FLUSH PRIVILEGES; ALTER USER \"root\"@\"%\" IDENTIFIED BY \"'$your_database_password'\"; ALTER USER \"root\"@\"localhost\" IDENTIFIED BY \"'$your_database_password'\"; CREATE DATABASE '$your_database_name'"; exit;';

    echo 'First query done...Creating your db user...';

    docker exec --user=root -it $container_id bash -c 'mysql -u root -p'$your_database_password' -sNe "CREATE USER \"'$your_database_username'\"@\"%\" IDENTIFIED BY \"'$your_database_password'\"; GRANT ALL ON '$your_database_name'.* TO \"'$your_database_username'\"@\"%\" "; exit;';

    echo 'Setting your administration password...';
    enc_admin_password=$(echo -n "$your_admin_password" | sha1sum | awk '{print $1}');

    docker exec --user=root -it $container_id bash -c 'mysql -u root -p'$your_database_password' cms_ide -sNe "UPDATE IGNORE users SET password=\"'$enc_admin_password'\", username=\"'$your_admin_username'\", fullname=\"'$your_admin_username'\" WHERE superadmin=\"1\" "; exit;';


    echo 'Moving tables to new database...';

    docker exec --user=root -it $container_id bash -c 'mysql -u root -p'$your_database_password' cms_ide -sNe "show tables" | while read table; do mysql -u root -p'$your_database_password' -sNe "RENAME TABLE cms_ide.$table TO '$your_database_name'.$table"; done; exit;';

    echo 'All required database changes applied.';
    echo "Access your website at https://$your_domain_name/, administration area at https://$your_domain_name/$your_admin_url";

fi
