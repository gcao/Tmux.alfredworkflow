extern crate alfred_tmux_workflow;

use alfred_tmux_workflow::tmux::Tmux;

fn main() {
    let mut tmux = Tmux::new();
    let window = tmux.windows.get_mut(0).unwrap();
    window.load_panes();
}
