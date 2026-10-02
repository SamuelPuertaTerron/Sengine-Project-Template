@echo off
:: ============================================================================
::  create_game.bat
::
::  Creates a new Sengine game project under Projects\<Name>, then runs that
::  project's build.bat, which uses premake to generate Projects\<Name>\<Name>.sln.
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
echo [create_game] Generating Projects\%SG_NAME%\%SG_NAME%.sln ...
call "Projects\%SG_NAME%\build.bat" --no-pause
if errorlevel 1 (
    echo [create_game] Project files were created, but generating the solution failed.
    goto :fail
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
# Engine namespaces, plus project names already used in the generated solution.
$reserved = @('Sengine', 'Raylib', 'ImGui', 'std', 'entt', 'nlohmann', 'Projects', 'Resources',
              'Engine', 'Editor', 'Example', 'Box2d', 'ImGuiBase', 'sol2', 'ThirdParty')
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
		Renderer2D::BeginFrame(Raylib::SKYBLUE);

		Renderer2D::EndFrame();
	}

	void __NAME__::OnDestroy()
	{
	}
}//namespace __NAME__
:::ENDFILE

:::FILE premake5.lua
-- __NAME__ workspace, generated by create_game.bat.
-- Run build.bat in this folder to (re)generate __NAME__.sln.
--
-- Layout:
--   __NAME__.sln     the solution, next to this file
--   __NAME__.vcxproj next to this file, so Show All Files shows src/ and Resources/
--   build/           the Engine and ThirdParty .vcxproj files
--   bin/, bin-int/   all compiled output, the Engine and ThirdParty included

local project_dir  = _MAIN_SCRIPT_DIR
local sengine_root = path.getabsolute(project_dir .. "/../../Sengine")
local sengine_dir  = sengine_root .. "/Sengine/"
local build_dir    = project_dir .. "/build"

-- Globals the Sengine and ThirdParty premake scripts read. cwd stays the
-- Sengine root so those scripts behave exactly as they do in Sengine.sln;
-- their output folders are redirected into this project further down.
cwd       = sengine_root
outputdir = "%{cfg.buildcfg}-%{cfg.system}-%{cfg.architecture}"

IncludeDir = {}
IncludeDir["Engine"]       = sengine_dir  .. "Engine/src"
IncludeDir["RaylibDir"]    = sengine_root .. "/ThirdParty/raylib/include"
IncludeDir["Entt"]         = sengine_root .. "/ThirdParty/entt"
IncludeDir["Box2D"]        = sengine_root .. "/ThirdParty/box2d/include"
IncludeDir["ImGuiBase"]    = sengine_root .. "/ThirdParty/imguibase"
IncludeDir["Nlohmannjson"] = sengine_root .. "/ThirdParty/nlohmannjson/include"
IncludeDir["Sol2"]         = sengine_root .. "/ThirdParty/sol2/include"

local wks = workspace "__NAME__"
    configurations { "Debug", "Release" }
    architecture "x64"
    startproject "__NAME__"
    location (project_dir)

    flags { "MultiProcessorCompile" }

    group "Sengine"
        include(sengine_dir .. "Engine")
        -- include(sengine_dir .. "Editor")
    group ""

    group "ThirdParty"
        include(sengine_root .. "/ThirdParty/Box2d")
        include(sengine_root .. "/ThirdParty/Entt")
        include(sengine_root .. "/ThirdParty/ImGuiBase")
        include(sengine_root .. "/ThirdParty/raylib")
        include(sengine_root .. "/ThirdParty/nlohmannjson")
        include(sengine_root .. "/ThirdParty/sol2")
    group ""

project "__NAME__"
    -- Keep the game's project file in this folder, next to src/ and Resources/.
    -- Visual Studio's Show All Files lists the folder the .vcxproj is in, and
    -- the filter tree mirrors the folders on disk only when paths start here.
    location (project_dir)

    language "C++"
    cppdialect "C++20"
    kind "ConsoleApp"

    -- Running from Visual Studio starts here, so Resources/ is found.
    debugdir (project_dir)

    pchheader "__NAME__Globals.h"
    pchsource "src/__NAME__Globals.cpp"

    files
    {
        "src/**.h",
        "src/**.cpp",
    }

    includedirs
    {
        "src",
        "%{IncludeDir.Engine}",
        "%{IncludeDir.RaylibDir}",
        "%{IncludeDir.Box2D}",
        "%{IncludeDir.Entt}",
        "%{IncludeDir.ImGuiBase}",
        "%{IncludeDir.Nlohmannjson}",
        "%{IncludeDir.Sol2}"
    }

    links
    {
        "Engine",
        "raylib",
    }

    -- Absolute source path, so the copy works no matter where the build runs from.
    postbuildcommands
    {
        "{COPYDIR} \"" .. project_dir .. "/Resources\" \"%{cfg.targetdir}/Resources\""
    }

    filter "system:windows"
        systemversion "latest"

        defines
        {
            "FE_PLATFORM_WINDOWS",
            "_CRT_SECURE_NO_WARNINGS"
        }

        links
        {
            "opengl32",
            "gdi32",
        }

    filter "system:linux"
        defines { "FE_PLATFORM_LINUX" }

        links
        {
            "GL",
            "pthread",
            "dl",
            "X11",
            "m"
        }

    filter "configurations:Debug"
        defines { "FE_DEBUG" }
        runtime "Debug"
        symbols "on"

    filter "configurations:Release"
        defines { "FE_RELEASE" }
        kind "WindowedApp"
        runtime "Release"
        optimize "on"
        symbols "off"

    filter {}

-- Every project in the solution writes its binaries into this project's bin
-- folders. The Engine and ThirdParty project files go into build/, so nothing
-- is generated inside the Sengine submodule and no two solutions share an
-- intermediate folder. The game's own project file stays where it is (above).
for _, prj in ipairs(wks.projects) do
    project(prj.name)
        filter {}
        if prj.name ~= "__NAME__" then
            location (build_dir)
        end
        targetdir (project_dir .. "/bin/"     .. outputdir .. "/%{prj.name}")
        objdir    (project_dir .. "/bin-int/" .. outputdir .. "/%{prj.name}")
end
:::ENDFILE

:::FILE build.bat
@echo off
:: Generates __NAME__.sln with premake.
:: Defaults to Visual Studio 2022. To pick another generator, set
:: PREMAKE_ACTION first, e.g.  set PREMAKE_ACTION=gmake2
setlocal
pushd "%~dp0"

set "SENGINE_ROOT=%~dp0..\..\Sengine"
set "PREMAKE="

:: Use the premake5.exe that ships somewhere inside the Sengine submodule...
for /r "%SENGINE_ROOT%" %%F in (premake5.exe) do if exist "%%F" if not defined PREMAKE set "PREMAKE=%%F"

:: ...or fall back to one on PATH.
if not defined PREMAKE for %%P in (premake5.exe) do set "PREMAKE=%%~$PATH:P"

if not defined PREMAKE (
    echo [build] Could not find premake5.exe inside Sengine or on PATH.
    set "BUILD_ERROR=1"
    goto :end
)

if not defined PREMAKE_ACTION set "PREMAKE_ACTION=vs2022"

"%PREMAKE%" %PREMAKE_ACTION%
set "BUILD_ERROR=%ERRORLEVEL%"

:end
popd
if /i not "%~1"=="--no-pause" pause
exit /b %BUILD_ERROR%
:::ENDFILE

:::FILE .gitignore
# Generated by premake
*.sln
*.vcxproj
*.vcxproj.filters
*.vcxproj.user
Makefile
*.make

# Build output
build/
bin/
bin-int/
.vs/
:::ENDFILE