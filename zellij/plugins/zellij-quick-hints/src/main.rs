use std::collections::BTreeMap;
use zellij_tile::prelude::*;

const ACTIVE_SECONDS: f64 = 20.0;

const PATTERNS: &[(&str, &str)] = &[
    ("local-id-27", r"[a-zA-Z0-9]{27}"),
    ("local-id-21", r"[a-zA-Z0-9]{21}"),
    ("email", r"[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}"),
    ("markdown-url", r"\[[^]]*\]\(([^)]+)\)"),
    (
        "url",
        r"(?:https?://|git@|git://|ssh://|ftp://|file:///)\S+",
    ),
    ("diff-a", r"--- a/(\S+)"),
    ("diff-b", r"\+\+\+ b/(\S+)"),
    ("docker-sha256", r"sha256:([0-9a-f]{64})"),
    ("path", r"(?:[.\w\-@~]+)?(?:/[.\w\-@]+)+"),
    ("hex-color", r"#[0-9a-fA-F]{6}"),
    (
        "uuid",
        r"[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}",
    ),
    ("ipfs", r"Qm[0-9a-zA-Z]{44}"),
    ("sha", r"[0-9a-f]{7,40}"),
    ("ipv4", r"\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}"),
    ("ipv6", r"[A-f0-9:]+:+[A-f0-9:]+[%\w\d]+"),
    ("hex-address", r"0x[0-9a-fA-F]+"),
    ("number", r"[0-9]{4,}"),
];

#[derive(Default)]
struct State {
    focused_pane: Option<PaneId>,
    highlighted_pane: Option<PaneId>,
    status: String,
}

register_plugin!(State);

impl ZellijPlugin for State {
    fn load(&mut self, _configuration: BTreeMap<String, String>) {
        request_permission(&[
            PermissionType::ReadApplicationState,
            PermissionType::ChangeApplicationState,
            PermissionType::ReadCliPipes,
            PermissionType::WriteToClipboard,
        ]);
        subscribe(&[
            EventType::PaneUpdate,
            EventType::HighlightClicked,
            EventType::Timer,
            EventType::PermissionRequestResult,
        ]);
        set_selectable(true);
        self.status = "approve permissions, then press Alt y in a terminal pane".to_owned();
    }

    fn pipe(&mut self, pipe_message: PipeMessage) -> bool {
        match pipe_message.name.as_str() {
            "activate" => self.activate_or_toggle(),
            "clear" => self.clear_highlights(),
            _ => {}
        }

        if let PipeSource::Cli(id) = &pipe_message.source {
            cli_pipe_output(id, &format!("{}\n", self.status));
            unblock_cli_pipe_input(id);
        }
        false
    }

    fn update(&mut self, event: Event) -> bool {
        match event {
            Event::PaneUpdate(manifest) => {
                self.focused_pane = focused_terminal_pane(&manifest);
            }
            Event::HighlightClicked {
                pane_id,
                matched_string,
                ..
            } => {
                if Some(pane_id) == self.highlighted_pane {
                    copy_to_clipboard(trim_match(&matched_string));
                    self.clear_highlights();
                }
            }
            Event::Timer(_) => self.clear_highlights(),
            Event::PermissionRequestResult(status) => match status {
                PermissionStatus::Granted => {
                    self.status = "permissions granted; hidden in background".to_owned();
                    set_selectable(false);
                    hide_self();
                }
                PermissionStatus::Denied => {
                    self.status = "permissions denied; quick hints cannot run".to_owned();
                    set_selectable(true);
                }
            },
            _ => {}
        }
        true
    }

    fn render(&mut self, _rows: usize, _cols: usize) {
        println!("zellij-quick-hints");
        println!("{}", self.status);
    }
}

impl State {
    fn activate_or_toggle(&mut self) {
        let pane_id = match get_focused_pane_info() {
            Ok((_tab_index, PaneId::Terminal(pane_id))) => PaneId::Terminal(pane_id),
            Ok((_tab_index, PaneId::Plugin(pane_id))) => {
                self.status = format!("focused pane is plugin_{pane_id}; focus a terminal pane");
                return;
            }
            Err(error) => {
                self.status = format!("failed to get focused pane: {error}");
                return;
            }
        };

        if let Some(previous_pane) = self.highlighted_pane {
            if previous_pane == pane_id {
                self.clear_highlights();
                return;
            }
        };

        self.clear_highlights();
        set_pane_regex_highlights(pane_id, highlights());
        self.highlighted_pane = Some(pane_id);
        set_timeout(ACTIVE_SECONDS);
        self.status = format!("highlighted {pane_id:?}; Alt-click a match to copy");
        hide_self();
    }

    fn clear_highlights(&mut self) {
        if let Some(pane_id) = self.highlighted_pane.take() {
            clear_pane_highlights(pane_id);
            self.status = format!("cleared {pane_id:?}");
        }
    }
}

fn focused_terminal_pane(manifest: &PaneManifest) -> Option<PaneId> {
    manifest
        .panes
        .values()
        .flatten()
        .find(|pane| pane.is_focused && !pane.is_plugin)
        .map(|pane| PaneId::Terminal(pane.id))
}

fn highlights() -> Vec<RegexHighlight> {
    PATTERNS
        .iter()
        .map(|(kind, pattern)| RegexHighlight {
            pattern: (*pattern).to_owned(),
            style: HighlightStyle::BackgroundEmphasis1,
            layer: HighlightLayer::Hint,
            context: BTreeMap::from([("kind".to_owned(), (*kind).to_owned())]),
            on_hover: false,
            bold: false,
            italic: false,
            underline: false,
            tooltip_text: Some("Alt-click to copy".to_owned()),
        })
        .collect()
}

fn trim_match(text: &str) -> String {
    text.trim_matches(|ch| matches!(ch, ')' | ']' | '}' | ',' | '.' | ';' | ':'))
        .to_owned()
}
