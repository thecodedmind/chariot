require "gtk2"
require "libkaiser"
require "codedmind"

class Chariot
  def initialize
    @root_window = Gtk::Window.new
    @root_window.set_size_request(350, 150)
    @root_window.signal_connect('destroy') { Gtk.main_quit }
    @athena = CodedMind.new
    @athena.load_directory "#{$ROOTDIR}/brains/"
    
  end
  def refresh
    @root_window.signal_connect('key_press_event') { |w, e|
      puts e.keyval
      if e.keyval == 65473
        if @codewin == nil
          @codewin = Gtk::Window.new
          @codewin.title = "Live Evaluation"
          @codewin.set_size_request(500, 450)
          @codewin.signal_connect('destroy') { @codewin = nil }
          @code = Gtk::Table.new 5, 6, false
          @cbox = Gtk::TextView.new
          @coutwin = Gtk::Window.new
          @cout = Gtk::TextView.new
          @coutwin.add @cout
          @coutwin.title = "Eval Output"
          @coutwin.show_all
          @coutwin.set_size_request(500, 450)
          @codewin.add @code
          @code.attach @cbox, 0, 2, 1, 6, Gtk::EXPAND|Gtk::FILL, Gtk::EXPAND|Gtk::FILL, 1, 1
          @codewin.show_all
          @cbox.signal_connect('key_press_event') { |w, e|
          #  puts e
            if e.keyval == 65474
              result = eval @cbox.buffer.text
              @cout.buffer.text += "\n#{result}"
            end
          }
        end
      end
    }
    @main = Gtk::Table.new 3, 6, false
    @entry = Gtk::Entry.new
    @send = Gtk::Button.new "Send"
    @txt = Gtk::TextView.new
    #@txt.buffer.text = "Your 1st Gtk::TextView widget!"
    @txts = Gtk::ScrolledWindow.new
    @txts.border_width = 5
    @txts.add(@txt)
    @txts.set_policy(Gtk::POLICY_AUTOMATIC, Gtk::POLICY_ALWAYS)
    
    # Placing
    @main.attach @txts, 0, 5, 0, 2, Gtk::FILL|Gtk::EXPAND, Gtk::FILL|Gtk::EXPAND
    @main.attach @entry, 0, 5, 2, 3, Gtk::EXPAND|Gtk::FILL, Gtk::SHRINK
    @main.attach @send, 5, 6, 2, 3, Gtk::SHRINK, Gtk::SHRINK
    @root_window.add @main
    
    # Events
    @send.signal_connect('clicked') {
      sendToBot
    }
    
    # Begin Render
    @root_window.show
    @txts.show
    @txt.show
    @main.show
    @entry.show
    @send.show
  end

  def sendToBot
    @txt.buffer.text += "\n[You] "+@entry.text

    reply = @athena.reply "user", @entry.text
    @entry.text = ""
    @txt.buffer.text += "\n[Athena] "+reply
  end
  def begin
    @txt.buffer.text = "[Athena] Hello, my name is Athena. I'll be your assistant."
    Gtk.main
  end
end
