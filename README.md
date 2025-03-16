```plaintext
          _____                 _____                     _____                     _____          
         /\    \               |\    \                   /\    \                   /\    \         
        /::\____\              |:\____\                 /::\    \                 /::\    \        
       /::::|   |              |::|   |                /::::\    \               /::::\    \       
      /:::::|   |              |::|   |               /::::::\    \             /::::::\    \      
     /::::::|   |              |::|   |              /:::/\:::\    \           /:::/\:::\    \     
    /:::/|::|   |              |::|   |             /:::/  \:::\    \         /:::/__\:::\    \    
   /:::/ |::|   |              |::|   |            /:::/    \:::\    \        \:::\   \:::\    \   
  /:::/  |::|___|______        |::|___|______     /:::/    / \:::\    \     ___\:::\   \:::\    \  
 /:::/   |::::::::\    \       /::::::::\    \   /:::/    /   \:::\ ___\   /\   \:::\   \:::\    \ 
/:::/    |:::::::::\____\     /::::::::::\____\ /:::/____/     \:::|    | /::\   \:::\   \:::\____\
\::/    / ~~~~~/:::/    /    /:::/~~~~/~~/____/ \:::\    \     /:::|____| \:::\   \:::\   \::/    /
 \/____/      /:::/    /    /:::/    /           \:::\    \   /:::/    /   \:::\   \:::\   \/____/ 
             /:::/    /    /:::/    /             \:::\    \ /:::/    /     \:::\   \:::\    \     
            /:::/    /    /:::/    /               \:::\    /:::/    /       \:::\   \:::\____\    
           /:::/    /     \::/    /                 \:::\  /:::/    /         \:::\  /:::/    /    
          /:::/    /       \/____/                   \:::\/:::/    /           \:::\/:::/    /     
         /:::/    /                                   \::::::/    /             \::::::/    /      
        /:::/    /                                     \::::/    /               \::::/    /       
        \::/    /                                       \::/____/                 \::/    /        
         \/____/                                         ~~                        \/____/      
```                           
# Music Youtube Downloader Script

![Illustration](media/illu.jpg)

This script automates the process of downloading audio from specified URLs using `yt-dlp`, extracting the audio, and embedding album cover thumbnails in a square format. It organizes the downloaded music files into a structured directory based on the uploader and album information.

## Requirements

Before running the script, ensure you have the following installed:

- [yt-dlp](https://github.com/yt-dlp/yt-dlp): A command-line program to download videos from YouTube and other video platforms.
- [ffmpeg](https://ffmpeg.org/): A complete solution to record, convert and stream audio and video.

You can install these tools using your package manager. For example, on Ubuntu, you can run:

```bash
sudo apt update
sudo apt install yt-dlp ffmpeg
```

Alternatively, you can use the provided `shell.nix` file to create a Nix development environment that includes all necessary dependencies. This file defines a Nix shell with `ffmpeg` and `yt-dlp` as build inputs. To enter the Nix shell, simply run:

```bash
nix-shell
```

## Usage

1. **Prepare a URL file**: Create a text file named `url.txt` in the same directory as the script. Each line of this file should contain a URL to the audio you want to download.

2. **Run the script**: Execute the script in your terminal:

   ```bash
   ./dl.sh
   ```

3. **Output Directory**: The downloaded music files will be saved in the `../02_MUSIC_DL` directory, organized by uploader and album.

4. **Log File**: The script generates a log file named `download.log` that records the progress of the downloads, including timestamps for each action taken. You can check this file for details on the download process and any issues encountered.

## Features

- Downloads the best audio quality available.
- Extracts audio and converts it to MP3 format.
- Embeds album cover thumbnails directly into the MP3 files.
- Automatically renames artist folders to uppercase for consistency.
- Handles existing files gracefully to avoid duplicate downloads.
- Logs the download process to a `download.log` file for tracking and troubleshooting.

## Troubleshooting

- If you encounter issues with missing dependencies, ensure that both `yt-dlp` and `ffmpeg` are correctly installed and accessible in your system's PATH.
- If the script fails to run, check the permissions of the script file. You may need to make it executable:

  ```bash
  chmod +x dl.sh
  ```

- If you experience issues during the download process, check the `download.log` file for error messages and additional information.

## Additional Tools

Additional tools are available in the scripts/ folder, listed below. Each of these scripts has its documentation provided in the same folder.

- merge.sh: merges folders that start in the same way
- merge-subfolders.sh: merges subfolders that have the same name


## License

This script is provided as-is without any warranty. Feel free to modify and use it according to your needs.

## Acknowledgments

This script utilizes `yt-dlp` and `ffmpeg`, which are powerful tools for media downloading and processing. For more information, refer to their respective documentation.

*The image was generated with [the mistral chatbot](https://chat.mistral.ai/)*

## Disclaimer

This script is intended for testing and educational purposes only. It is important to respect intellectual property rights and the terms of service of the platforms from which you are downloading content. Please ensure that you have the necessary permissions to download and use any media files.