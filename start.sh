#!/bin/bash

# Function to configure DNS settings
configure_dns() {
    echo "Configuring DNS settings..."
    # Backup the current resolv.conf
    cp /etc/resolv.conf /etc/resolv.conf.backup
    # Use Google's public DNS servers
    echo "nameserver 8.8.8.8
nameserver 8.8.4.4" >/etc/resolv.conf
    echo "DNS configuration updated."
}

# Function to start Jupyter Lab
start_jupyter() {
    echo "Starting Jupyter Lab..."
    cd /notebooks/ &&
        nohup jupyter lab \
            --allow-root \
            --ip=0.0.0.0 \
            --no-browser \
            --ServerApp.trust_xheaders=True \
            --ServerApp.disable_check_xsrf=False \
            --ServerApp.allow_remote_access=True \
            --ServerApp.allow_origin='*' \
            --ServerApp.allow_credentials=True \
            --FileContentsManager.delete_to_trash=False \
            --FileContentsManager.always_delete_dir=True \
            --FileContentsManager.preferred_dir=/notebooks \
            --ContentsManager.allow_hidden=True \
            --LabServerApp.copy_absolute_path=True \
            --ServerApp.token='' \
            --ServerApp.password='' &>./jupyter.log &
    echo "Jupyter Lab started."
}

# Function to export environment variables
export_env_vars() {
    echo "Exporting environment variables..."
    printenv | grep -E '^RUNPOD_|^PATH=|^_=' | awk -F= '{ print "export " $1 "=\"" $2 "\"" }' >>/etc/rp_environment
    echo 'source /etc/rp_environment' >>~/.bashrc
    echo "Environment variables exported."
}

# Function to run the custom script
run_custom_script() {
    echo "Running custom script..."
    # curl -sSf https://raw.githubusercontent.com/vjumpkung/vjump-runpod-notebooks-and-script/refs/heads/main/custom_script_kohya_ss.sh | bash -s -- -y
    cd /notebooks/
    curl https://raw.githubusercontent.com/vjumpkung/vjump-runpod-notebooks-and-script/refs/heads/main/kohya_ss_notebooks/run_kohya_ss_gui.ipynb >run_kohya_ss_gui.ipynb
    curl https://raw.githubusercontent.com/vjumpkung/vjump-runpod-notebooks-and-script/refs/heads/main/kohya_ss_notebooks/ui/main.py >./ui/main.py
    curl https://raw.githubusercontent.com/vjumpkung/vjump-runpod-notebooks-and-script/refs/heads/main/kohya_ss_notebooks/ui/google_drive_download.py >./ui/google_drive_download.py

    echo "Updating kohya-ss GUI"

    cd kohya_ss && git pull --ff-only && python ./setup/validate_requirements.py --requirements requirements_runpod.txt

    echo "Update Completed"
    echo "Custom script executed."
}

# Main execution sequence
echo "Pod Started"
configure_dns
start_jupyter
run_custom_script
export_env_vars
echo "Start script(s) finished, pod is ready to use."
sleep infinity
