# Cmder-prompt

This is a custom prompt for [Cmder](http://cmder.net/) (the alternative console emulator for Windows). 
This prompt is inspired by [Spaceship Prompt](https://github.com/denysdovhan/spaceship-prompt/) for zsh.
This was based on the work done in [Cmder Powerline Prompt](https://github.com/AmrEldib/cmder-powerline-prompt). The implementation has been rewritten, and also stops all the other cmder prompt filters from also running (this improves performance).

# Requirements

A patched [nerd font](https://github.com/ryanoasis/nerd-fonts) is needed for the symbols I use. I use a patched version of Consolas but any font patched with nerd font should work.


# Install

Copy the `.lua` files, and place it in `%CMDER_ROOT%/config` folder.  
Restart Cmder to load the prompt.

# Configuration

Edit the `_prompt_config.lua` file and add or remove sections as needed.
The `PROMPT_color` function can be mixed in between `PROMPT_section` to color the leader text differently.


# TODOs

Improve documentation - currently it's easiest to read the source of the `section_xxx.lua` files and the `_prompt_config.lua` files.
  