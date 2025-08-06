#!/bin/bash

if (( $EUID != 0 )); then
    printf "\033[0;33m<jexactyl-region> \033[0;31m[✕]\033[0m Please run this program as root \n"
    exit
fi

watermark="\033[0;33m<jexactyl-region> \033[0;32m[✓]\033[0m"
target_dir=""

chooseDirectory() {
    echo -e "<jexactyl-region> [1] /var/www/jexactyl   (choose this if you installed the panel using the official Jexactyl documentation)"
    echo -e "<jexactyl-region> [2] /var/www/pterodactyl (choose this if you migrated from Pterodactyl to Jexactyl)"

    while true; do
        read -p "<jexactyl-region> [?] Choose jexactyl directory [1/2]: " choice
        case "$choice" in
            1)
                target_dir="/var/www/jexactyl"
                break
                ;;
            2)
                target_dir="/var/www/pterodactyl"
                break
                ;;
            *)
                echo -e "\033[0;33m<jexactyl-region> \033[0;31m[✕]\033[0m Invalid choice. Please enter 1 or 2."
                ;;
        esac
    done
}

startPterodactyl(){
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | sudo -E bash -
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
    nvm install node || {
        printf "${watermark} nvm command not found, trying to source nvm script directly... \n"
        . ~/.nvm/nvm.sh
        nvm install node
    }
    apt update

    npm i -g yarn
    yarn
    export NODE_OPTIONS=--openssl-legacy-provider
    yarn build:production || {
        printf "${watermark} node: --openssl-legacy-provider is not allowed in NODE_OPTIONS \n"
        export NODE_OPTIONS=
        yarn build:production
    }
    sudo php artisan optimize:clear
}

installModule(){
    chooseDirectory
    printf "${watermark} Installing module... \n"
    cd "$target_dir"
    rm -rvf jexactyl-region
    printf "${watermark} Previous module successfully removed \n"
    git clone https://github.com/freeutka/jexactyl-region.git
    printf "${watermark} Cloning git repository \n"
    rm -f resources/scripts/components/server/console/RegionStatBlock.tsx
    rm -f resources/scripts/components/server/console/ServerDetailsBlock.tsx
    rm -rvf resources/scripts/assets/regions
    printf "${watermark} Previous files successfully removed \n"
    cd jexactyl-region
    mv resources/regions "$target_dir/resources/scripts/assets/"
    mv resources/RegionStatBlock.tsx "$target_dir/resources/scripts/components/server/console/"
    mv resources/ServerDetailsBlock.tsx "$target_dir/resources/scripts/components/server/console/"
    printf "${watermark} New files successfully installed \n"
    rm -rvf "$target_dir/jexactyl-region"
    printf "${watermark} Git repository deleted \n"
    cd "$target_dir"

    printf "${watermark} Module fully and successfully installed in your jexactyl repository \n"

    while true; do
        read -p '<jexactyl-region> [?] Do you want rebuild panel assets [y/N]? ' yn
        case $yn in
            [Yy]* ) startPterodactyl; break;;
            [Nn]* ) exit;;
            * ) exit;;
        esac
    done
}

while true; do
    read -p '<jexactyl-region> [✓] Are you sure that you want to install "jexactyl-regions" module [y/N]? ' yn
    case $yn in
        [Yy]* ) installModule; break;;
        [Nn]* ) printf "${watermark} Canceled \n"; exit;;
        * ) exit;;
    esac
done