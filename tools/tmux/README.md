# tmux

## Description
Mangement of multiple windows, split screens, sessions and more.
If you are using the CLI very often, you want this.

## Commands
> tmux
Opens a tmux session

> tmux list-sessions
List all open session

### Commands in tmux session
<Prefix> = CTRL+B (default) 

- <Prefix> ?
Opens commands.
Rest you can see there.
Exit list with "q".

- <Prefix> C
Create new Window

- <Prefix> 1
Change to Window with index 1

- <Prefix> %
Split Pane vertically

- <Prefix> =
Split Pane horizontel

- <Prefix> x
Close Pane

## Config
Config lays under $HOME/.tmux.conf .
You could e.g. change the status bar color to Tokio Night. 
See example conf in this folder.

## Scripts
You can create scripts to automatically load and start your sessions.
This way you can just start.
See example script called "session" in this folder.


