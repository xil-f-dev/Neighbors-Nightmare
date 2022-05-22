# Neighbour's Nightmare

### A wifi craking tool based on Aircrack-ng

## Setup

> Config variables can be found in the beginning of the script

Download the latest [release](https://github.com/xil-f-dev/Neighbors-Nightmare/releases)

Execute the .sh file as root

#### This tool assumes that you have already installed the **aircrack-ng** suite, running **Gnome desktop environement** (or you can edit the terminal_cmd variable).

## Usage

This script can be used with options or with a semi-automatic interface (easy mode)

To use the easy interface, simply execute the .sh file

## Options

| Command          | Usage                                                                                                                                                                                                                                                          |
| ---------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `--help` or `-h` | Shows the help page                                                                                                                                                                                                                                            |
| `-m <1-4>`       | Specifies the mode to use, where :<br/>`-m 1` starts a network scan<br/>`-m 2` asks you for a recent .cap file to try with a wordlist<br/>`-m 3` enables monitor mode on your network interface<br/>`-m 4` disables monitor mode on the monitor mode interface |

## Configuration

In the configuration section, at the beginning of the file, you can set your default wordlist, the interface and the terminal command, which will be used to open a new terminal window.

## Tutorial

###### If you just want to test your network, here is a simple guide about how to use this tool

First, execute the script as root with option `-m 3` to enable monitor mode.
Then, re-execute the script with option `-m 1` to scan the networks around you.
You can press "Ctrl + c" or double press "q" to exit the scan process when you find your network.
After that, enter the number assigned by the program to your network, then select the third option to try to catch a handshake. I recommend using a decent amount of deauth requests (30 - 50) and stop it when you get the handshake, but it's up to you.
After getting the handshake, stop the scanning process, then re execute the script with options `-m 2` to select the recent capture file. Choose the most recent one and choose a password list. The cracking process should start and you should get the password of the network if it is in the password list.

###### Please report any issue to help us improve this tool, and make it even useful
