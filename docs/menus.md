# The menu engine

## Concepts

### Menu

A menu is actually a fairly general concept. The point of creating the menu subsystem was to have common code for common things such as input handling, managing a cursor with options, etc.

...You could abuse the menu system for many things. You could probably rewrite the whole game to only be a menu, I suppose. Your call on how to use the features!

### The menu stack

An important feature of menus is that you can open a menu from within a menu. (Think Pokémon's start menu -> inventory -> confirmation box -> party screen, for example)

The menu stack is there to allow opening a menu independently of whether one is already open or not. Of course, there will be an issue when it comes to restoring state, but that's up to the individual menu.

### Actions

Again, to mutualize code, buttons don't simply run functions, they trigger "actions", such as validating the selection or moving the cursor. An action can be anything, really.

## How to make a menu

Here is a sample menu header:

```
LanguageMenuHeader::
    db BANK("Language menu")
    dw LanguageMenuInit
    db PADF_START | PADF_DOWN | PADF_UP
    db 0 ; Prevent repeat press
    dw 0, 0, 0, ForceMenuValidation, 0, 0, 0, 0
    db 0 ; Previous item
    db 1 ; Allow wrapping
    db 0 ; Default item
    db NB_LANGUAGES ; Size
    dw LanguageMenuRedraw
    dw LanguageMenuItems
    dw 0
```

First element is the bank where the rest of the data is located. This allows splitting the data better, leading to better ROM usage.

Second element is the init function. This function, if not NULL, is ran right as the `AddMenu` function is called. (Not the first time `ProcessMenus` is ran after!) Typically this is used to load some tiles, set up some tilemaps and/or raster FX, etc.

Third element is which buttons should be considered. Not all menus use all buttons (here, no cancellation is possible, so no B button, for example.)

Fourth element is whether "repeat press" is enabled. This is a (fairly common) mechanism where holding a button for long enough causes it to start being pressed repeatedly, hence the name. Note that it only applies to the d-pad, not other buttons.

Fifth element is an array of "button hooks": these function pointers are called whenever the correspondig button is pressed, and can override the action or do something custom.

Sixth element is simply the default value for the "previous item" field.

Seventh element is whether the menu should wrap vertically.

Eigth element is simply the menu item selected by default. Ninth is the number of elements

## Button hooks

Button hooks are called with the current menu action in B, HL pointing to the function, DE pointing to the struct's MiscState, and A = H | L. The action taken is overridden by writing to `wMenuAction`.

## Redraw funcs

The redraw func is called with the current menu item in B, HL pointing to the function, DE pointing to the struct's MiscState, and A = H | L.