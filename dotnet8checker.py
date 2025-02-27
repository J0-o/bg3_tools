import subprocess
import logging
import mobase
from PyQt6.QtCore import QCoreApplication, QTimer
from PyQt6.QtWidgets import QMessageBox

logger = logging.getLogger(__name__)

class DotNet8Checker(mobase.IPluginDiagnose):
    __organizer: mobase.IOrganizer

    def __init__(self):
        super().__init__()

    def init(self, organizer: mobase.IOrganizer):
        self.__organizer = organizer
        # Delay diagnostic check to ensure MO2 is fully initialized.
        QTimer.singleShot(2000, self.delayedDiagnosticCheck)
        return True

    def delayedDiagnosticCheck(self):
        logger.info("Running delayed .NET 8+ Checker...")
        if self.is_dotnet_8_installed():
            logger.info(".NET 8+ is installed.")
        else:
            logger.warning(".NET 8+ is missing!")
            self.show_warning_popup()

    def name(self):
        return "Check .NET 8+"

    def localizedName(self):
        return "Check .NET 8+"

    def author(self):
        return "J"

    def description(self):
        return self.tr("Checks if .NET 8 or later is installed using the command line.")

    def version(self):
        return mobase.VersionInfo(1, 0, 0, mobase.ReleaseType.FINAL)

    def requirements(self):
        return []

    def settings(self) -> list[mobase.PluginSetting]:
        return []

    def activeProblems(self) -> list[int]:
        return []

    def shortDescription(self, key: int) -> str:
        return self.tr(".NET 8+ is missing!")

    def fullDescription(self, key: int) -> str:
        return self.tr(
            "The required .NET 8 or later is missing from your system. "
            "Please install it from Microsoft's official website."
        )

    def hasGuidedFix(self, key: int) -> bool:
        return False

    def startGuidedFix(self, key: int) -> None:
        pass

    def tr(self, value: str):
        return QCoreApplication.translate("DotNet8Checker", value)

    def is_dotnet_8_installed(self) -> bool:
        try:
            result = subprocess.run(
                ["dotnet", "--list-runtimes"],
                capture_output=True,
                text=True,
                check=True
            )
            for line in result.stdout.splitlines():
                if line.startswith("Microsoft.NETCore.App "):
                    version = line.split()[1]
                    major_version = int(version.split('.')[0])
                    if major_version >= 8:
                        return True
        except (subprocess.CalledProcessError, FileNotFoundError):
            return False
        return False

    def show_warning_popup(self):
        main_window = self.__organizer.mainWindow() if hasattr(self.__organizer, "mainWindow") else None
        QMessageBox.warning(
            main_window,
            "Missing .NET 8+",
            "The required .NET 8 or later is missing.\n"
            "Please install it from Microsoft's official website.\n\n"
            "Balder's Gate 3 MO2 plugin requires this to function correctly.",
        )

def createPlugin():
    return DotNet8Checker()