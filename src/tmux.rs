use regex::Regex;

pub struct Window {
    index: u32,
    name: String,
    is_active: bool,
    is_last: bool,
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
                 (?P<name>[^(]+)\s+
                 (?P<last>-)?
                 (?P<active>\*)?
                 Z?\s+\(
            ").unwrap();
        }

        let cap = WINDOW_RE.captures(representation).unwrap();
        let index = cap.name("index").map(|cap| cap.as_str().parse::<u32>().unwrap()).unwrap();
        let name = cap.name("name").map(|cap| cap.as_str().parse::<String>().unwrap()).unwrap();
        let is_active = cap.name("active").is_some();
        let is_last = cap.name("last").is_some();

        Window {
            index, name, is_active, is_last
        }
    }
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