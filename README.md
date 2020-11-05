# chariot
An extendable desktop assistant, written in Ruby.

Designed as a desktop UI/CLI assistant, a conversational engine that can call off to arbitrary scripts, which can effect the assistant itself, give control over the OS, or any other functionality you'd expect from something like Google's assistant or Siri, but completely open source, and designed around simplicity.

It is heavily work in progress right now, only a basic framework is ready.

# Components
## chariot
The graphical user interface, written using GTK3.

## codedmind
The Conversational engine library that the GUI calls to, uses a custom scripting interface to add triggers and commands. Can be launched independantly of the GUI as a terminal input.
Syntactically, it's inspired by RiveScript, and should be fully compatible with most of its triggers, especially atomic triggers.
