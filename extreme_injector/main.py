#!/usr/bin/env python3
"""
Extreme Injector v1 by curelessdoktor
Linux-only .so injector — inject shared libraries into running processes.
"""

import os
import subprocess
import sys
from pathlib import Path

from PyQt6.QtCore import Qt
from PyQt6.QtGui import QColor, QPalette, QIcon, QAction
from PyQt6.QtWidgets import (
    QApplication,
    QMainWindow,
    QWidget,
    QVBoxLayout,
    QHBoxLayout,
    QLabel,
    QLineEdit,
    QPushButton,
    QGroupBox,
    QListWidget,
    QListWidgetItem,
    QFileDialog,
    QMessageBox,
    QDialog,
    QDialogButtonBox,
    QAbstractItemView,
)


# Colors matching Extreme Injector
BG_BLUE = "#1E90FF"
BUTTON_BG = "#D3D3D3"
BUTTON_TEXT = "#333333"
LABEL_COLOR = "#FFFFFF"
LIST_HEADER_COLOR = "#333333"


def get_running_processes():
    """List running processes: (pid, name) from /proc."""
    procs = []
    try:
        for entry in Path("/proc").iterdir():
            if not entry.is_dir() or not entry.name.isdigit():
                continue
            pid = entry.name
            try:
                exe = (entry / "exe").readlink()
                name = os.path.basename(exe)
                cmdline = (entry / "cmdline").read_text(errors="ignore").replace("\x00", " ").strip()
                if cmdline:
                    first = cmdline.split()[0] if cmdline else ""
                    if first:
                        name = os.path.basename(first)
            except (OSError, PermissionError):
                name = "?"
            procs.append((pid, name))
    except PermissionError:
        pass
    procs.sort(key=lambda x: x[1].lower())
    return procs


class ProcessSelectDialog(QDialog):
    def __init__(self, parent=None):
        super().__init__(parent)
        self.setWindowTitle("Select Process")
        self.setMinimumSize(400, 400)
        layout = QVBoxLayout(self)
        self.list_widget = QListWidget()
        self.list_widget.setAlternatingRowColors(True)
        self.list_widget.setSelectionMode(QAbstractItemView.SelectionMode.SingleSelection)
        layout.addWidget(self.list_widget)
        btn = QDialogButtonBox(
            QDialogButtonBox.StandardButton.Ok | QDialogButtonBox.StandardButton.Cancel
        )
        btn.accepted.connect(self.accept)
        btn.rejected.connect(self.reject)
        layout.addWidget(btn)
        self.list_widget.itemDoubleClicked.connect(self.accept)
        self._pid = None
        self._name = None

    def set_processes(self, procs):
        self.list_widget.clear()
        for pid, name in procs:
            item = QListWidgetItem(f"{name} (PID {pid})")
            item.setData(Qt.ItemDataRole.UserRole, (pid, name))
            self.list_widget.addItem(item)

    def selected(self):
        row = self.list_widget.currentRow()
        if row < 0:
            return None, None
        item = self.list_widget.item(row)
        return item.data(Qt.ItemDataRole.UserRole)

    def accept(self):
        self._pid, self._name = self.selected()
        super().accept()


class AboutDialog(QDialog):
    def __init__(self, parent=None):
        super().__init__(parent)
        self.setWindowTitle("About")
        layout = QVBoxLayout(self)
        label = QLabel(
            "<h2>Extreme Injector v1</h2>"
            "<p><b>by curelessdoktor</b></p>"
            "<p>Inject .so (shared object) files into running Linux processes.</p>"
            "<p>Uses ptrace-based injection. On many systems you may need:</p>"
            "<pre>echo 0 | sudo tee /proc/sys/kernel/yama/ptrace_scope</pre>"
            "<p>Build the injector first: <code>cd injector && make</code></p>"
        )
        label.setWordWrap(True)
        layout.addWidget(label)
        license_label = QLabel(
            "<hr><p><b>License</b></p>"
            "<p>Copyright (c) 2026 curelessdoktor.</p>"
            "<p>I coded this for fun. Please don't steal my code — use it, learn from it, "
            "and give credit where it's due. If I don't fix the bugs, fork the project "
            "and fix them yourself; that's what forks are for.</p>"
            "<p>No warranty. Use at your own risk.</p>"
        )
        license_label.setWordWrap(True)
        layout.addWidget(license_label)
        btn = QDialogButtonBox(QDialogButtonBox.StandardButton.Ok)
        btn.accepted.connect(self.accept)
        layout.addWidget(btn)


class SettingsDialog(QDialog):
    def __init__(self, inject_path: str, parent=None):
        super().__init__(parent)
        self.setWindowTitle("Settings")
        self.inject_path = inject_path
        layout = QVBoxLayout(self)
        layout.addWidget(QLabel("Path to inject binary:"))
        self.path_edit = QLineEdit(inject_path)
        layout.addWidget(self.path_edit)
        btn = QDialogButtonBox(
            QDialogButtonBox.StandardButton.Ok | QDialogButtonBox.StandardButton.Cancel
        )
        btn.accepted.connect(self._save)
        btn.rejected.connect(self.reject)
        layout.addWidget(btn)

    def _save(self):
        self.inject_path = self.path_edit.text().strip()
        self.accept()


class MainWindow(QMainWindow):
    def __init__(self):
        super().__init__()
        self.setWindowTitle("Extreme Injector v1 by curelessdoktor")
        self.setMinimumSize(520, 420)
        self.setStyleSheet(f"""
            QMainWindow, QWidget {{
                background-color: {BG_BLUE};
            }}
            QLabel {{
                color: {LABEL_COLOR};
                font-size: 12px;
            }}
            QGroupBox {{
                color: {LABEL_COLOR};
                font-weight: bold;
                border: 1px solid #4169E1;
                border-radius: 4px;
                margin-top: 8px;
            }}
            QGroupBox::title {{
                subcontrol-origin: margin;
                left: 10px;
                padding: 0 4px;
            }}
            QPushButton {{
                background-color: {BUTTON_BG};
                color: {BUTTON_TEXT};
                border: 1px solid #999;
                padding: 6px 12px;
                min-width: 80px;
            }}
            QPushButton:hover {{
                background-color: #C0C0C0;
            }}
            QPushButton:pressed {{
                background-color: #A9A9A9;
            }}
            QLineEdit, QListWidget {{
                background-color: white;
                color: #333;
                border: 1px solid #999;
            }}
        """)

        central = QWidget()
        self.setCentralWidget(central)
        layout = QVBoxLayout(central)
        layout.setSpacing(10)
        layout.setContentsMargins(12, 12, 12, 12)

        # Process name row
        proc_row = QHBoxLayout()
        proc_row.addWidget(QLabel("Process Name:"))
        self.process_edit = QLineEdit()
        self.process_edit.setPlaceholderText("Select a process or enter name/PID")
        proc_row.addWidget(self.process_edit, 1)
        self.select_btn = QPushButton("Select")
        self.select_btn.clicked.connect(self._on_select_process)
        proc_row.addWidget(self.select_btn)
        layout.addLayout(proc_row)

        # Inject list group
        group = QGroupBox("Inject List")
        group_layout = QHBoxLayout(group)
        left_btns = QVBoxLayout()
        left_btns.setSpacing(6)
        add_btn = QPushButton("Add SO")
        add_btn.clicked.connect(self._on_add_so)
        enable_btn = QPushButton("Enable/Disable")
        enable_btn.clicked.connect(self._on_enable_disable)
        remove_btn = QPushButton("Remove")
        remove_btn.clicked.connect(self._on_remove)
        clear_btn = QPushButton("Clear")
        clear_btn.clicked.connect(self._on_clear)
        left_btns.addWidget(add_btn)
        left_btns.addWidget(enable_btn)
        left_btns.addWidget(remove_btn)
        left_btns.addWidget(clear_btn)
        left_btns.addStretch()
        group_layout.addLayout(left_btns)

        list_header = QLabel("SO Name")
        list_header.setStyleSheet("color: #333; font-weight: bold; margin-bottom: 2px;")
        list_col = QVBoxLayout()
        list_col.addWidget(list_header)
        self.list_widget = QListWidget()
        self.list_widget.setMinimumHeight(200)
        self.list_widget.setAlternatingRowColors(True)
        self.list_widget.setSelectionMode(QAbstractItemView.SelectionMode.ExtendedSelection)
        list_col.addWidget(self.list_widget, 1)
        group_layout.addLayout(list_col, 1)
        layout.addWidget(group)

        # Bottom buttons
        bottom = QHBoxLayout()
        bottom.addStretch()
        about_btn = QPushButton("About")
        about_btn.clicked.connect(self._on_about)
        settings_btn = QPushButton("Settings")
        settings_btn.clicked.connect(self._on_settings)
        inject_btn = QPushButton("Inject")
        inject_btn.clicked.connect(self._on_inject)
        bottom.addWidget(about_btn)
        bottom.addWidget(settings_btn)
        bottom.addWidget(inject_btn)
        layout.addLayout(bottom)

        self._pid = None
        self._process_name = None
        self._inject_binary = self._default_inject_path()

    def _default_inject_path(self):
        base = Path(__file__).resolve().parent
        return str(base / "injector" / "inject")

    def _on_select_process(self):
        procs = get_running_processes()
        dlg = ProcessSelectDialog(self)
        dlg.set_processes(procs)
        if dlg.exec() == QDialog.DialogCode.Accepted and dlg._pid:
            self._pid = dlg._pid
            self._process_name = dlg._name
            self.process_edit.setText(f"{self._process_name} (PID {self._pid})")

    def _on_add_so(self):
        path, _ = QFileDialog.getOpenFileName(
            self,
            "Add shared object",
            "",
            "Shared objects (*.so *.so.*);;All files (*)",
        )
        if path:
            item = QListWidgetItem(path)
            item.setData(Qt.ItemDataRole.UserRole, {"path": path, "enabled": True})
            self.list_widget.addItem(item)

    def _on_enable_disable(self):
        for item in self.list_widget.selectedItems():
            data = item.data(Qt.ItemDataRole.UserRole) or {}
            data["enabled"] = not data.get("enabled", True)
            item.setData(Qt.ItemDataRole.UserRole, data)
            # Visual: strikethrough or normal
            font = item.font()
            font.setStrikeOut(not data["enabled"])
            item.setFont(font)

    def _on_remove(self):
        for item in self.list_widget.selectedItems():
            self.list_widget.takeItem(self.list_widget.row(item))

    def _on_clear(self):
        self.list_widget.clear()

    def _on_about(self):
        AboutDialog(self).exec()

    def _on_settings(self):
        dlg = SettingsDialog(self._inject_binary, self)
        if dlg.exec() == QDialog.DialogCode.Accepted:
            self._inject_binary = dlg.inject_path

    def _on_inject(self):
        if not self._pid:
            # Try to resolve from process name field
            text = self.process_edit.text().strip()
            if not text:
                QMessageBox.warning(
                    self,
                    "No process",
                    "Select a process first (click Select or enter name/PID).",
                )
                return
            # Allow "name" or "PID" or "name (PID 123)"
            if text.isdigit():
                self._pid = text
                self._process_name = f"pid{text}"
            else:
                # Find by name
                procs = get_running_processes()
                for pid, name in procs:
                    if name == text or f"{name} (PID {pid})" == text:
                        self._pid = pid
                        self._process_name = name
                        break
                if not self._pid:
                    QMessageBox.warning(
                        self,
                        "Process not found",
                        f'No running process found for "{text}".',
                    )
                    return

        if not os.path.isfile(self._inject_binary):
            QMessageBox.critical(
                self,
                "Injector not found",
                f'Build the injector first:\n  cd "{Path(self._inject_binary).parent}" && make\n\nThen set the path in Settings if needed.',
            )
            return

        count = 0
        errors = []
        for i in range(self.list_widget.count()):
            item = self.list_widget.item(i)
            data = item.data(Qt.ItemDataRole.UserRole) or {}
            if not data.get("enabled", True):
                continue
            path = data.get("path") or item.text()
            if not os.path.isfile(path):
                errors.append(f"File not found: {path}")
                continue
            try:
                result = subprocess.run(
                    [self._inject_binary, "-p", str(self._pid), path],
                    capture_output=True,
                    text=True,
                    timeout=15,
                )
                if result.returncode == 0:
                    count += 1
                else:
                    errors.append(f"{Path(path).name}: {result.stderr or result.stdout or 'failed'}")
            except subprocess.TimeoutExpired:
                errors.append(f"{Path(path).name}: timeout")
            except Exception as e:
                errors.append(f"{Path(path).name}: {e}")

        if count:
            QMessageBox.information(
                self,
                "Inject",
                f"Injected {count} library/libraries.",
            )
        if errors:
            QMessageBox.warning(
                self,
                "Inject",
                "Some injections failed:\n\n" + "\n".join(errors[:10])
                + ("\n..." if len(errors) > 10 else ""),
            )


def main():
    app = QApplication(sys.argv)
    app.setApplicationName("Extreme Injector")
    win = MainWindow()
    win.show()
    sys.exit(app.exec())


if __name__ == "__main__":
    main()
