#SingleInstance Off
#NoTrayIcon
#Include <AuxLib>

    AuxLibLoad( "default" )

    AddMenuItemEditor("ProjectMenu")
    AddMenu( "ProjectMenu" )
    AddMenu( "ProjectMenu", "&README.md...`tR", "OnReadme", BrowserPath )
    AddMenu( "ProjectMenu" )
    AddMenu( "ProjectMenu", "&Sync with Upstream`tS", "OnSyncWithUpstream", ConEmuPath )
    AddMenu( "ProjectMenu", "&AutoGroq...`tA", "OnAutoGroqWsl", ResDir "github.ico" )
    AddMenu( "ProjectMenu", "Open &Config Local`tL", "OnOpenConfigLocal", VSCodePath )
    AddMenu( "ProjectMenu" )
    AddMenuItemEditProjectMenu("ProjectMenu")
    ShowMenu( "ProjectMenu" )
    ExitApp
return ; end of script's auto-execute section

MenuHandler:
    MsgBox % "MenuHandler was called."
return

OnSyncWithUpstream:
    SyncWithUpstream(ProjectDir, "https://github.com/jgravelle/AutoGroq.git")
return

OnAutoGroq:
{
    SplitPath, A_LineFile,, ProjectDir
    SplitPath, ProjectDir,, ProjectDir
    ShiftPressed := GetKeyState("Shift","P")
    Script =
    (

        set ProjectName=AutoGroq
        set ProjectDir=%ProjectDir%
        set should_install=%ShiftPressed%
        call e exist param AutoGroq >nul 2>&1
        if "!errorlevel!" equ "1" set should_install=1

        if "!should_install!" equ "1" `(
            pushd "!ProjectDir!" || goto :exit
            echo.
            call e remove
            call e
            echo Installing Streamlit
            call conda install -c conda-forge streamlit
            echo Installing Python packages from requirements.txt
            pip install -r requirements.txt
            pip install "pydantic>=1.0,<2.0"
            popd
        `)

        pushd "!ProjectDir!" || goto :exit
        call e
        streamlit run AutoGroq\main.py
        popd
    )
        
    RunBat({ Visible: "ConEmu", Colors: true, Pause: true }, StripBat( Script ) )
    return
}

OnAutoGroqWsl:
{
    SplitPath, A_LineFile,, ProjectDir
    SplitPath, ProjectDir,, ProjectDir

    WorkingDir := A_UserProfile . "\.autogenstudio"
    explorerInfo := GetExplorerInfo()
    if (ProjectDir = explorerInfo["path"]) {
        WorkingDir := ProjectDir . "\.autogenstudio"
    }

    ProjectDirWsl := ConvertToWslPath(ProjectDir)
    WorkingDirWsl := ConvertToWslPath(WorkingDir)
    ShiftPressed := GetKeyState("Shift","P")
    BatchScript =
    (

        echo !yellow!Initializing AutoGrok in !green!%WorkingDir%!yellow! ...!nc!
        md "%WorkingDir%"
        dir /b /s "%WorkingDir%"
    )
    BashScript =
    (
        
        # Check if AutoGroq is installed in the user home directory
        should_install=%ShiftPressed%
        if [[ -f "/home/ubuntu/anaconda3/envs/AutoGroq/bin/python" && "$should_install" == "0" ]]; then
            echo "AutoGroq already installed."
            cd "%ProjectDirWsl%" || { echo "Failed to change directory."; exit 1; }
            if [[ "$(readlink /home/ubuntu/.autogenstudio)" != "%WorkingDirWsl%" ]]; then
                rm -rf /home/ubuntu/.autogenstudio
                ln -s "%WorkingDirWsl%" /home/ubuntu/.autogenstudio
            fi
            source /home/ubuntu/anaconda3/etc/profile.d/conda.sh
            conda activate AutoGroq || { echo "Failed to activate environment."; exit 1; }
            streamlit run AutoGroq/main.py
        else
            source /home/ubuntu/anaconda3/etc/profile.d/conda.sh

            echo "Creating new conda environment."
            rm -rf /home/ubuntu/anaconda3/envs/AutoGroq
            conda create -n AutoGroq python=3.11 -y || { echo "Failed to create environment."; exit 1; }

            echo "Activating the environment."
            conda activate AutoGroq || { echo "Failed to activate environment."; exit 1; }

            cd "%ProjectDirWsl%" || { echo "Failed to change directory."; exit 1; }
            pip install -r requirements.txt || { echo "Failed to install requirements."; exit 1; }

            if [[ "$(readlink /home/ubuntu/.autogenstudio)" != "%WorkingDirWsl%" ]]; then
                rm -rf /home/ubuntu/.autogenstudio
                ln -s "%WorkingDirWsl%" /home/ubuntu/.autogenstudio
            fi

            echo "AutoGroq installed successfully."
        fi
    )
    Options := { Visible: "ConEmu", Colors: true, Pause: true, Admin: false }
    RunBash( Options, StripBat(BatchScript), StripBat(BashScript), [], true, true )
    return
}

OnOpenConfigLocal:
{
    SplitPath, A_LineFile,, ProjectDir
    SplitPath, ProjectDir,, ProjectDir

    FilePath := ProjectDir . "\AutoGroq\configs\config_local.py"
    ExampleFilePath := ProjectDir . "\AutoGroq\configs\config_local.py.example"
    ShiftPressed := GetKeyState("Shift", "P")

    if (ShiftPressed) {
        Try FileCopy, %ExampleFilePath%, %FilePath%, 1 ; 1 forces the overwrite
    }

    Run, %VSCodePath% "%FilePath%"
    return
}
