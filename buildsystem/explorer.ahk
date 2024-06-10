#SingleInstance, Force
#NoTrayIcon
#Include <AuxLib>

    AuxLibLoad()

    SetRegView 64
    RegRead, DeveloperDir, HKCU\Software\Developer, DeveloperDir
    RegRead, ProjectDir, HKCU\Software\Developer, ProjectDir

    ; Project Menu
    AddMenu( "ProjectMenu", "Open Visual Studio &Code`tC", "OnOpenVscode", VSCodePath )
    AddMenu( "ProjectMenu" )
    AddMenu( "ProjectMenu", "&README.md...`tR", "OnReadme", BrowserPath )
    AddMenu( "ProjectMenu" )
    AddMenu( "ProjectMenu", "&Sync with Upstream`tS", "OnSyncWithUpstream", ConEmuPath )
    AddMenu( "ProjectMenu", "&AutoGroq...`tA", "OnAutoGroq", ResDir "github.ico" )
    AddMenu( "ProjectMenu", "AutoGroq &WSL...`tW", "OnAutoGroqWsl", ResDir "github.ico" )
    AddMenu( "ProjectMenu" )
    AddMenu( "ProjectMenu", "&Edit Project Menu...`tE", "OnEditProjectMenu", VSCodePath )
    ShowMenu( "ProjectMenu" )
    ExitApp
return ; end of script's auto-execute section

MenuHandler:
    MsgBox % "MenuHandler was called."
return

OnSyncWithUpstream:
    BatchScript =
    (

        pushd "%ProjectDir%" || goto :error

        git remote | findstr /c:"upstream" >nul
        if !errorlevel! equ 0 `(
            echo Upstream remote already exists.
        `) else `(
            git remote add upstream https://github.com/jgravelle/AutoGroq.git || goto :error
            echo Upstream remote added.
        `)

        git fetch upstream || goto :error
        git checkout main || goto :error

        call t merge upstream/main

        popd
    )
    Options := { Visible: "ConEmu", Pause: true, Admin: true }
    RunBat( Options, StripBat(BatchScript) )
return

OnAutoGroq:
{
    RegRead, ProjectDir, HKCU\Software\Developer, ProjectDir
    ShiftPressed := GetKeyState("Shift","P")
    Script =
    (

        set ProjectName=AutoGroq
        set ProjectDir=%ProjectDir%
        set CLONE_STATUS=0
        set SHOULD_INSTALL=%ShiftPressed%
        call e exist param AutoGroq >nul 2>&1
        if "!errorlevel!" equ "1" set SHOULD_INSTALL=1
        if not exist C:\Users\j mklink /j C:\Users\j C:\Users\!username!

        if "!SHOULD_INSTALL!" equ "1" `(
            pushd "!ProjectDir!" || goto :exit
            echo.
            call e remove
            call e
            echo Installing Streamlit
            call conda install -c conda-forge streamlit
            echo Installing Python packages from requirements.txt
            pip install -r requirements.txt
            pip install autogenstudio
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
    RegRead, ProjectDir, HKCU\Software\Developer, ProjectDir
    ProjectDirWsl := ConvertToWslPath( ProjectDir )
    WorkingDir := ConvertToWslPath( A_UserProfile ) . "/.autogenstudio"
    ShiftPressed := GetKeyState("Shift","P")
    BatchScript =
    (

        echo !yellow!Installing AutoGroq...!nc!
    )
    BashScript =
    (
        
        # Check if AutoGroq is installed in the user home directory
        should_install=%ShiftPressed%
        if [[ -f "/home/ubuntu/anaconda3/envs/AutoGroq/bin/python" && "$should_install" == "0" ]]; then
            echo "AutoGroq already installed."
            cd "%ProjectDirWsl%" || { echo "Failed to change directory."; exit 1; }
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
            
            rm -rf /home/ubuntu/.autogenstudio
            ln -s %WorkingDir% /home/ubuntu/.autogenstudio

            echo "AutoGroq installed successfully."
        fi
    )
    Options := { Visible: "ConEmu", Colors: true, Pause: true, Admin: false }
    RunBash( Options, StripBat(BatchScript), StripBat(BashScript), [], true, true )
}
return
