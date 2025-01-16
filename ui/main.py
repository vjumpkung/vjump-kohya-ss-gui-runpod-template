import ipywidgets as widgets
from IPython.display import display
import subprocess
import os
import shlex
import requests
import threading


platform_id = os.environ["PLATFORM_ID"]  # get platform type


class Envs:
    def __init__(self):
        self.CIVITAI_TOKEN = ""
        self.HUGGINGFACE_TOKEN = ""


envs = Envs()

model_url = "https://gist.githubusercontent.com/vjumpkung/4663f8a608699ac80f1769a6bd0daee4/raw/9f3411a6eb51bd4244bb655bee8b458330284f89/vjump_notebook_model_template.json"
clip_vae_url = "https://gist.githubusercontent.com/vjumpkung/421667857264bc11686cb28026f374dd/raw/6210ee04b03f362043ccc1c2974d8d3df7da26b6/vjump_notebook_clipvae.json"


def get_model_list():

    r = requests.get(model_url)

    data = r.json()

    return data


def get_clip_list():

    r = requests.get(clip_vae_url)

    data = r.json()

    return data


def test():
    status_header = widgets.HTML('<h2 style="width: 250px;">Import สำเร็จ!</h2>')
    headers = widgets.HBox([status_header])
    display(headers)


def setup():
    settings = []
    input_list = [
        ("CIVITAI_TOKEN", "CivitAI API Key", "Paste your API key here", ""),
        ("HUGGINGFACE_TOKEN", "Huggingface API Key", "Paste your API key here", ""),
    ]

    save_button = widgets.Button(description="Save", button_style="success")
    output = widgets.Output()

    for key, input_label, placeholder, input_value in input_list:
        label = widgets.Label(input_label, layout=widgets.Layout(width="100px"))
        textfield = widgets.Text(
            placeholder=placeholder,
            value=input_value,
            layout=widgets.Layout(width="400px"),
        )
        settings.append((key, textfield))
        row = [label, textfield]
        print("")
        display(widgets.HBox(row))

    def on_save(button):
        output.clear_output()
        with output:
            for key, textInput in settings:
                if key == "CIVITAI_TOKEN":
                    envs.CIVITAI_TOKEN = textInput.value
                elif key == "HUGGINGFACE_TOKEN":
                    envs.HUGGINGFACE_TOKEN = textInput.value
            print("\nSaved ✔")

    save_button.on_click(on_save)
    display(save_button, output)


def download(name: str, url: str, type: str):
    destination = ""

    if type in ["sd15", "sdxl"]:
        destination = "./model/checkpoints/"
    elif type in ["flux", "sd3"]:
        destination = "./model/unet/"
    elif type == "clip":
        destination = "./model/clip/"
    elif type == "vae":
        destination = "./model/vae/"

    print(f"Starting download: {name}")

    if "civitai" in url:
        if envs.CIVITAI_TOKEN != "":
            if "?" in url:
                url += f"&token={envs.CIVITAI_TOKEN}"
            else:
                url += f"?token={envs.CIVITAI_TOKEN}"

        command = f"aria2c --console-log-level=error -c -x 16 -s 16 -k 1M {url} --dir={destination} --content-disposition=true --download-result=hide {url}"

        with subprocess.Popen(
            shlex.split(command),
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            text=True,
            bufsize=1,
        ) as sp:
            print("\033[?25l", end="")  # Hide cursor
            for line in sp.stdout:
                print(f"\r{line.strip()}", end="", flush=True)
            print("\033[?25h")  # Show cursor

    elif "huggingface" in url:
        command = (
            f"wget -q --show-progress --content-disposition {url} -P {destination}"
        )

        if envs.HUGGINGFACE_TOKEN != "":
            command += f' --header="Authorization: Bearer {envs.HUGGINGFACE_TOKEN}"'

        with subprocess.Popen(
            shlex.split(command),
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            text=True,
            bufsize=1,
        ) as sp:
            print("\033[?25l", end="")  # Hide cursor
            for line in sp.stdout:
                print(f"\r{line.strip()}", end="", flush=True)
            print("\033[?25h")  # Show cursor

    print(f"\nDownload completed: {name}")


def completed_message():
    completed = widgets.Button(
        description="Completed", button_style="success", icon="check"
    )
    print("\n")
    display(completed)


def select_pretrained_model():
    checkboxes = []
    models_header = widgets.HTML('<h3 style="width: 200px;">Pretrained Model List</h3>')
    headers = widgets.HBox([models_header])
    display(headers)
    get_model = get_model_list()

    for item in get_model:
        checkbox = widgets.Checkbox(
            value=False,
            description=item["id"],
            indent=False,
            layout={"width": "50px"},
        )
        model_name = widgets.HTML(
            f'<div class="jp-RenderedText" style="padding-left: 0; white-space: nowrap; display: inline-flex;">'
            f'<pre>{item["name"]}</pre></div>'
        )
        cb_item = widgets.HBox([checkbox, model_name])
        checkboxes.append((item, checkbox))
        display(cb_item)

    download_button = widgets.Button(description="Download", button_style="success")
    output = widgets.Output()

    def on_press(button):
        with output:
            output.clear_output()
            try:
                for _res, _checkbox in checkboxes:
                    if _checkbox.value:
                        download(_res["name"], _res["url"], _res["id"])
                completed_message()

            except KeyboardInterrupt:
                print("\n\n--Download Model interrupted--")

    download_button.on_click(on_press)

    display(download_button, output)


def select_clip_vae_model():
    checkboxes = []
    models_header = widgets.HTML('<h3 style="width: 200px;">VAE/CLIP Model List</h3>')
    headers = widgets.HBox([models_header])
    display(headers)
    get_model = get_clip_list()

    for item in get_model:
        checkbox = widgets.Checkbox(
            value=False,
            description=item["id"],
            indent=False,
            layout={"width": "50px"},
        )
        model_name = widgets.HTML(
            f'<div class="jp-RenderedText" style="padding-left: 0; white-space: nowrap; display: inline-flex;">'
            f'<pre>{item["name"]}</pre></div>'
        )
        cb_item = widgets.HBox([checkbox, model_name])
        checkboxes.append((item, checkbox))
        display(cb_item)

    download_button = widgets.Button(description="Download", button_style="success")
    output = widgets.Output()

    def on_press(button):
        with output:
            output.clear_output()
            try:
                for _res, _checkbox in checkboxes:
                    if _checkbox.value:
                        download(_res["name"], _res["url"], _res["id"])
                completed_message()

            except KeyboardInterrupt:
                print("\n\n--Download Model interrupted--")

    download_button.on_click(on_press)

    display(download_button, output)


def launch_kohya_ss():

    models_header = widgets.HTML(
        '<h3 style="width: 200px;">เริ่มโปรแกรม Kohya-SS GUI ตรงนี้</h3>'
    )
    headers = widgets.HBox([models_header])
    display(headers)

    def run_gui(button):
        command = "python -u kohya_gui.py --noverify --headless --listen=0.0.0.0"

        if platform_id == "RUNPOD":
            proxy_url = f'URL : https://{os.environ.get("RUNPOD_POD_ID")}-{7860}.proxy.runpod.net'
        elif platform_id == "PAPERSPACE":
            proxy_url = f'URL : https://tensorboard-{os.environ.get("PAPERSPACE_FQDN")}'
        else:
            proxy_url = f"using gradio share url"
            command += " --share"

        os.chdir("kohya_ss/")  # Change to the kohya_ss directory

        try:
            # Start the subprocess with unbuffered output
            process = subprocess.Popen(
                shlex.split(command),
                stdout=subprocess.PIPE,
                stderr=subprocess.STDOUT,
                text=True,
                bufsize=1,  # Line buffering
            )

            # Function to read and print subprocess output in real-time
            def print_output():
                for line in iter(process.stdout.readline, ""):
                    if line:
                        print(line.strip(), flush=True)
                process.stdout.close()

            # Start the output thread
            output_thread = threading.Thread(target=print_output)
            output_thread.daemon = True
            output_thread.start()

            with output:
                print("kohya-ss GUI has been started see logs at console")
                print(proxy_url)

            # Wait for the subprocess to complete
            process.wait()
            output_thread.join()

        except KeyboardInterrupt:
            process.terminate()
            print("\n--Process terminated--")
        finally:
            os.chdir("/notebooks/")  # Restore the working directory

    start_button = widgets.Button(
        description="START kohya-ss GUI", button_style="primary"
    )
    output = widgets.Output()
    start_button.on_click(run_gui)

    display(start_button, output)
