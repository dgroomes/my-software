import {App, Editor, MarkdownView, Modal, Notice, Plugin} from 'obsidian';

export default class MyPlugin extends Plugin {

    async onload() {
        this.addRibbonIcon('dice', 'MyPlugin', () => {
            // Called when the user clicks the icon.
            new Notice('This is a notice!');
        });

        const statusBarItemEl = this.addStatusBarItem();
        statusBarItemEl.setText('MyPlugin says "hello" from the status bar');

        this.addCommand({
            id: 'my-plugin-open-sample-modal-simple',
            name: 'Open sample modal (simple)',
            callback: () => {
                new SampleModal(this.app).open();
            }
        });

        this.addCommand({
            id: 'my-plugin-sample-editor-command',
            name: 'Sample editor command',
            editorCallback: (editor: Editor) => {
                console.log(editor.getSelection());
                editor.replaceSelection('🚧Hello from MyPlugin!🚧');
            }
        });

        this.addCommand({
            id: 'my-plugin-open-sample-modal-complex',
            name: 'Open sample modal (complex)',
            checkCallback: (checking: boolean) => {
                const markdownView = this.app.workspace.getActiveViewOfType(MarkdownView);
                if (!markdownView) {
                    return false;
                }

                // When Obsidian is 'checking' the command, we need to return whether the command is allowed to run.
                // We don't want to actually do the "real" action.
                if (checking) {
                    return true;
                }

                new SampleModal(this.app).open();
            }
        });
    }
}

class SampleModal extends Modal {
    constructor(app: App) {
        super(app);
    }

    onOpen() {
        const {contentEl} = this;
        contentEl.setText('Woah!');
    }

    onClose() {
        const {contentEl} = this;
        contentEl.empty();
    }
}