@echo off
:: ============================================================================
::  create_game.bat
::
::  Creates a new Sengine game project under Projects\<Name> and then runs
::  build_sengine.bat so the new project gets picked up and compiled.
::
::  Usage:
::      create_game.bat              (prompts for a name)
::      create_game.bat MyGame       (no prompt)
::
::  The file templates live at the bottom of this script, after the
::  "exit /b" line. cmd never reads past that point; PowerShell extracts
::  them and replaces every __NAME__ with the game name.
:: ============================================================================
setlocal
pushd "%~dp0"

set "SG_ROOT=%CD%"
set "SG_SCRIPT=%~f0"
set "SG_NAME=%~1"
set "SG_INTERACTIVE="

if not defined SG_NAME (
    set "SG_INTERACTIVE=1"
    set /p "SG_NAME=Name of the game: "
)

if not defined SG_NAME (
    echo [create_game] No name given.
    goto :fail
)

if not exist "Sengine\" (
    echo [create_game] Sengine submodule folder not found next to this script.
    echo [create_game] Run: git submodule update --init --recursive
    goto :fail
)

echo.
echo [create_game] Creating Projects\%SG_NAME% ...

powershell -NoProfile -ExecutionPolicy Bypass -Command "$s=[IO.File]::ReadAllText($env:SG_SCRIPT); $m=[regex]::Match($s,'(?ms)^:::PS\r?\n(.*?)^:::ENDPS'); if(-not $m.Success){ Write-Host '[create_game] Internal error: PowerShell block missing.'; exit 2 }; Invoke-Expression $m.Groups[1].Value"
if errorlevel 1 goto :fail

echo.
if exist "build_sengine.bat" (
    echo [create_game] Running build_sengine.bat ...
    call "build_sengine.bat"
    if errorlevel 1 (
        echo [create_game] build_sengine.bat reported an error.
        goto :fail
    )
) else (
    echo [create_game] build_sengine.bat not found, skipping the build step.
)

echo.
echo [create_game] Done. Your game lives in Projects\%SG_NAME%
popd
if defined SG_INTERACTIVE pause
exit /b 0

:fail
popd
if defined SG_INTERACTIVE pause
exit /b 1

:: ============================================================================
::  Everything below this line is data, never executed by cmd.
:: ============================================================================

:::PS
$ErrorActionPreference = 'Stop'

$name    = $env:SG_NAME
$rootDir = $env:SG_ROOT

# The name becomes a namespace, a class and part of file names, so it has
# to be a valid C++ identifier.
if ($name -notmatch '^[A-Za-z_][A-Za-z0-9_]*$')
{
    Write-Host "[create_game] '$name' is not a valid name. Use letters, digits and _ only, and don't start with a digit."
    exit 1
}

# These would collide with namespaces the engine already uses.
$reserved = @('Sengine', 'Raylib', 'ImGui', 'std', 'entt', 'nlohmann', 'Projects', 'Resources')
if ($reserved -contains $name)
{
    Write-Host "[create_game] '$name' is reserved, pick another name."
    exit 1
}

$projectDir = Join-Path $rootDir (Join-Path 'Projects' $name)
if (Test-Path $projectDir)
{
    Write-Host "[create_game] '$projectDir' already exists, not overwriting it."
    exit 1
}

$self      = [IO.File]::ReadAllText($env:SG_SCRIPT)
$utf8      = New-Object System.Text.UTF8Encoding($false)
$templates = [regex]::Matches($self, '(?ms)^:::FILE[ \t]+(\S+)\r?\n(.*?)^:::ENDFILE')

if ($templates.Count -eq 0)
{
    Write-Host '[create_game] Internal error: no file templates found.'
    exit 1
}

foreach ($t in $templates)
{
    $relative = $t.Groups[1].Value.Replace('__NAME__', $name)
    $content  = $t.Groups[2].Value.Replace('__NAME__', $name)

    $path   = Join-Path $projectDir $relative
    $folder = Split-Path $path -Parent
    New-Item -ItemType Directory -Force -Path $folder | Out-Null

    [IO.File]::WriteAllText($path, $content, $utf8)
    Write-Host "  + Projects\$name\$relative"
}

exit 0
:::ENDPS

:::FILE Resources\Textures\.gitkeep
:::ENDFILE

:::FILE src\__NAME__Globals.h
#pragma once

#include <vector>

#include "Globals.h"
#include "Engine/Sengine.h"

namespace __NAME__
{
	using namespace Sengine;
}//namespace __NAME__
:::ENDFILE

:::FILE src\__NAME__Globals.cpp
#include "__NAME__Globals.h"
:::ENDFILE

:::FILE src\Main.cpp
#include "__NAME__Globals.h"
#include "__NAME__/__NAME__.h"

namespace __NAME__
{
	static int Main()
	{
		std::vector<std::unique_ptr<ILayer>> layers;
		layers.push_back(std::make_unique<__NAME__>());

		EngineSpecification spec;
		spec.Width = 1920;
		spec.Height = 1080;
		spec.Title = "__NAME__";
		spec.Render.VirtualWidth = 1920;
		spec.Render.VirtualHeight = 1080;
		spec.Render.Scaling = ScaleMode::Integer;

		Engine::CreateAndRun(spec, std::move(layers));

		return 0;
	}
}//namespace __NAME__

#if defined(FE_DEBUG)
int main()
{
	return __NAME__::Main();
}
#elif defined(FE_RELEASE) //FE_DEBUG
	#if defined(FE_PLATFORM_WINDOWS)
		#include <Windows.h>
		int APIENTRY WinMain(HINSTANCE hInst, HINSTANCE hInstPrev, PSTR cmdline, int cmdshow)
		{
			return __NAME__::Main();
		}
	#else //FE_PLATFORM_WINDOWS
		//Anything but Windows will use the default int main()
		int main()
		{
			return __NAME__::Main();
		}
	#endif //FE_PLATFORM_WINDOWS
#else //FE_RELEASE
	//No configuration define set, fall back to a console entry point.
	int main()
	{
		return __NAME__::Main();
	}
#endif
:::ENDFILE

:::FILE src\__NAME__\__NAME__.h
#pragma once

namespace __NAME__
{
	class __NAME__ : public ILayer
	{
	public:
		void OnCreate() override;
		void OnTick(float deltaTime) override;
		void OnDestroy() override;
	};
}//namespace __NAME__
:::ENDFILE

:::FILE src\__NAME__\__NAME__.cpp
#include "__NAME__Globals.h"
#include "__NAME__/__NAME__.h"

namespace __NAME__
{
	void __NAME__::OnCreate()
	{
	}

	void __NAME__::OnTick(float deltaTime)
	{
	}

	void __NAME__::OnDestroy()
	{
	}
}//namespace __NAME__
:::ENDFILE