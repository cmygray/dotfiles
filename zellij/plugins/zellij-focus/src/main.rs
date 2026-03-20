use std::collections::BTreeMap;
use zellij_tile::prelude::*;

#[derive(Default)]
struct State {
    pane_manifest: PaneManifest,
}

register_plugin!(State);

impl ZellijPlugin for State {
    fn load(&mut self, _configuration: BTreeMap<String, String>) {
        request_permission(&[
            PermissionType::ChangeApplicationState,
            PermissionType::ReadApplicationState,
        ]);
        subscribe(&[EventType::PaneUpdate]);
    }

    fn pipe(&mut self, pipe_message: PipeMessage) -> bool {
        match pipe_message.name.as_str() {
            "focus" => {
                if let Some(payload) = &pipe_message.payload {
                    if let Ok(pane_id) = payload.trim().parse::<u32>() {
                        focus_terminal_pane(pane_id, false);
                    }
                }
            }
            "list" => {
                let mut output = String::new();
                for (tab_idx, panes) in &self.pane_manifest.panes {
                    for p in panes {
                        let focus = if p.is_focused { " *" } else { "" };
                        output.push_str(&format!(
                            "tab={} id={} title={:?}{}\n",
                            tab_idx, p.id, p.title, focus
                        ));
                    }
                }
                if let PipeSource::Cli(ref id) = pipe_message.source {
                    cli_pipe_output(id, &output);
                }
            }
            _ => {}
        }
        if let PipeSource::Cli(id) = &pipe_message.source {
            unblock_cli_pipe_input(id);
        }
        false
    }

    fn update(&mut self, event: Event) -> bool {
        if let Event::PaneUpdate(manifest) = event {
            self.pane_manifest = manifest;
        }
        false
    }

    fn render(&mut self, _rows: usize, _cols: usize) {}
}
