import gi
gi.require_version('Gtk', '3.0')
from gi.repository import Gtk, Gdk

if __name__ == "__main__":
  display = Gdk.Display.get_default()
  if display is not None:
    print(Gdk.Display.get_default_cursor_size(display))
    print(Gdk.Display.get_maximal_cursor_size(display))
