"""Exercise the actual read-only doctor entrypoint against isolated fixtures."""
from pathlib import Path
import json
import os
import shutil
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]


class DoctorTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="hub-doctor-")
        self.addCleanup(self.temp.cleanup)
        root = Path(self.temp.name)
        self.hub = root / "hub"
        (self.hub / "scripts").mkdir(parents=True)
        shutil.copyfile(ROOT / "scripts" / "doctor.sh", self.hub / "scripts" / "doctor.sh")
        self.registry = {"plugins": [{"id": "optmem", "path": "optmem",
                                      "runtime_name": "optmem-hermes", "tracked_by_prs": []}]}
        self.save_registry()
        (self.hub / "prs.json").write_text('{"prs": []}', encoding="utf-8")
        self.home = root / "home"
        self.state = self.home / ".hermes"
        self.install_profile(self.state)
        binary = root / "bin"
        binary.mkdir()
        self.cli = binary / "hermes"
        self.cli.write_text("#!/bin/sh\nprintf 'enabled      user     0.3.0    optmem-hermes\\n'\n",
                            encoding="utf-8")
        self.cli.chmod(0o755)
        self.env = os.environ.copy()
        for key in ("HERMES_HOME", "HERMES_PROFILE", "XDG_DATA_HOME"):
            self.env.pop(key, None)
        self.env.update(HOME=str(self.home), PATH=str(binary) + os.pathsep + self.env["PATH"])

    def save_registry(self):
        (self.hub / "plugins.json").write_text(json.dumps(self.registry), encoding="utf-8")

    def install_profile(self, state):
        plugin = state / "plugins" / "optmem-hermes"
        plugin.mkdir(parents=True)
        (plugin / "plugin.yaml").write_text("name: optmem-hermes\n", encoding="utf-8")
        (state / "config.yaml").write_text("plugins: {}\n", encoding="utf-8")

    def run_doctor(self, *args):
        return subprocess.run(["bash", str(self.hub / "scripts" / "doctor.sh"), *args],
                              env=self.env, capture_output=True, text=True, timeout=20)

    def test_linux_default_home_and_runtime_plugin_identity(self):
        result = self.run_doctor()
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertIn(str(self.state), result.stdout)
        self.assertIn("plugin 'optmem-hermes' installed", result.stdout)
        self.assertIn("plugin 'optmem-hermes' enabled", result.stdout)
        self.assertNotIn("not cloned", result.stdout)
        self.assertNotIn("LifeOS API not reachable", result.stdout)

    def test_explicit_profile_uses_its_own_state(self):
        state = self.state / "profiles" / "work"
        self.install_profile(state)
        result = self.run_doctor("--profile", "work")
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertIn(f"HERMES_HOME = {state}", result.stdout)
        self.assertIn(str(state / "plugins" / "optmem-hermes"), result.stdout)

    def test_disabled_plugin_is_not_a_substring_green(self):
        self.cli.write_text("#!/bin/sh\nprintf 'disabled user 0.3.0 optmem-hermes\\n'\n",
                            encoding="utf-8")
        result = self.run_doctor()
        self.assertEqual(result.returncode, 0, result.stdout)
        self.assertIn("not enabled in this profile", result.stdout)
        self.assertNotIn("[OK] plugin 'optmem-hermes' enabled", result.stdout)

    def test_unknown_pr_reference_propagates_failure(self):
        self.registry["plugins"][0]["tracked_by_prs"] = ["missing/pr#1"]
        self.save_registry()
        result = self.run_doctor()
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("tracks unknown PR", result.stdout)
        self.assertNotIn("doctor: healthy", result.stdout)

    def test_missing_config_never_launches_bootstrap(self):
        (self.state / "config.yaml").unlink()
        self.cli.write_text("#!/bin/sh\nprintf 'BOOTSTRAP_LAUNCHED\\n'\nexit 42\n", encoding="utf-8")
        result = self.run_doctor()
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("runtime probe not launched", result.stdout)
        self.assertNotIn("exit 42", result.stdout)

    def test_invalid_profile_path_is_refused(self):
        result = self.run_doctor("--profile", "../default")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("invalid profile name", result.stderr)


if __name__ == "__main__":
    unittest.main()
