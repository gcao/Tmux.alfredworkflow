use regex::Regex;
use std::process::Command;

pub struct Tmux {
    pub windows: Vec<Window>,
}

impl Tmux {
    pub fn new() -> Tmux {
        let output = Command::new("tmux")
            .arg("list-windows")
            .output().unwrap_or_else(|e| {
                panic!("Failed to execute process: {}", e)
            });
        if !output.status.success() {
            let s = String::from_utf8_lossy(&output.stderr);
            panic!("Failed to execute process: {}", s)
        }

        let s = String::from_utf8_lossy(&output.stdout);
        let windows = s.trim().split("\n").collect::<Vec<&str>>().into_iter().map(|line| Window::new(line)).collect();
        Tmux {
            windows,
        }
    }
}

pub struct Window {
    pub index: u32,
    pub name: String,
    pub is_active: bool,
    pub is_last: bool,
    pub panes: Vec<Pane>,
}

impl Window {
    /// @representation is individual line of "tmux list-windows" output
    /// 
    /// 1: First  (3 panes) [238x80] [layout 8cf3,238x80,0,0{157x80,0,0,3,80x80,158,0[80x39,158,0,4,80x40,158,40,5]}] @2
    /// 2: DEV Z (4 panes) [238x80] [layout a0fa,238x80,0,0{157x80,0,0[157x39,0,0,6,157x40,0,40,7],80x80,158,0[80x39,158,0,8,80x40,158,40,9]}] @3
    /// 3: QA/PROD  (4 panes) [238x80] [layout f0ec,238x80,0,0{157x80,0,0[157x39,0,0,10,157x40,0,40,11],80x80,158,0[80x39,158,0,12,80x40,158,40,13]}] @4
    /// 4: Portals  (3 panes) [238x80] [layout 178e,238x80,0,0{157x80,0,0,14,80x80,158,0[80x39,158,0,15,80x40,158,40,16]}] @5
    /// 5: Portalsmain Z (3 panes) [238x80] [layout a72f,238x80,0,0{157x80,0,0,17,80x80,158,0[80x41,158,0,18,80x38,158,42,19]}] @6
    /// 6: - (3 panes) [238x80] [layout 66f8,238x80,0,0{157x80,0,0,20,80x80,158,0[80x41,158,0,21,80x38,158,42,22]}] @7
    /// 7: Speak2dial  (3 panes) [238x80] [layout e711,238x80,0,0{157x80,0,0,23,80x80,158,0[80x41,158,0,24,80x38,158,42,25]}] @8
    /// 8: Premier  (3 panes) [238x80] [layout 672b,238x80,0,0{157x80,0,0,26,80x80,158,0[80x41,158,0,27,80x38,158,42,28]}] @9
    /// 9: Gene  (3 panes) [238x80] [layout 2740,238x80,0,0{157x80,0,0,29,80x80,158,0[80x41,158,0,30,80x38,158,42,31]}] @10
    /// 10: RPS 2  (3 panes) [238x80] [layout a70d,238x80,0,0{157x80,0,0,32,80x80,158,0[80x41,158,0,33,80x38,158,42,34]}] @11
    /// 11: PML  (3 panes) [238x80] [layout 2727,238x80,0,0{157x80,0,0,35,80x80,158,0[80x41,158,0,36,80x38,158,42,37]}] @12
    /// 12: Alfred *Z (3 panes) [238x80] [layout 473e,238x80,0,0{157x80,0,0,38,80x80,158,0[80x41,158,0,39,80x38,158,42,40]}] @13 (active)
    pub fn new(representation: &str) -> Window {
        lazy_static! {
            static ref WINDOW_RE: Regex = Regex::new(r"(?x)
                ^(?P<index>[\d]+):\s+
                 (?P<name>[^(\-\*Z]+)?\s+
                 (?P<last>-)?
                 (?P<active>\*)?
                 Z?\s*\(
            ").unwrap();
        }

        let cap = WINDOW_RE.captures(representation).unwrap();
        let index = cap.name("index").map(|cap| cap.as_str().parse::<u32>().unwrap()).unwrap();
        let name_ = cap.name("name").map(|cap| cap.as_str().parse::<String>().unwrap());
        let name = if name_.is_some() {
                name_.unwrap()
            } else {
                "".to_string()
            };
        let is_active = cap.name("active").is_some();
        let is_last = cap.name("last").is_some();
        let panes = vec![];

        Window {
            index, name, is_active, is_last, panes,
        }
    }

    pub fn load_panes(&mut self) {
        let output = Command::new("tmux")
            .arg("list-panes")
            .arg("-t").arg(self.index.to_string())
            .output().unwrap_or_else(|e| {
                panic!("Failed to execute process: {}", e)
            });
        if !output.status.success() {
            let s = String::from_utf8_lossy(&output.stderr);
            panic!("Failed to execute process: {}", s)
        }

        let s = String::from_utf8_lossy(&output.stdout);
        self.panes = s.split("\n").collect::<Vec<&str>>().into_iter().map(|line| Pane::new(line)).collect();
    }
}

pub struct Pane {
    pub index: u32,
    pub active: bool,
}

impl Pane {
    pub fn new(representation: &str) -> Pane {
        let index = 0;
        let active = false;
        Pane {
            index, active,
        }
    }
}

pub struct PaneHistory {
}

#[cfg(test)]
mod tests {
    use super::Window;

    #[test]
    fn it_works() {
        let window = Window::new("12: Alfred *Z (3 panes) [238x80] [layout 473e,238x80,0,0{157x80,0,0,38,80x80,158,0[80x41,158,0,39,80x38,158,42,40]}] @13 (active)");
        assert_eq!(window.name, "Alfred");
    }
}