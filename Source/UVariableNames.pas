unit UVariableNames;
// Compofiller Studio by Yzi 2017-2018


// Pascal constants for variable names to avoid typos going unnoticed.
// The variable names are in ALL_CAPS to indicate that they're sort of like macros.

// These are the script variables that come from the Compofiller Studio GUI/IDE.
// The scripts internally define many other helper variables, and the script-defined
// variables may change between Compofiller Studio versions, but this unit (largely)
// defines the interface between the scripts and the GUI.

{$mode objfpc}{$H+}

interface

const
  // GUI/testing/preferences variables. These work like project-level variables.
  PREFS_AUTOREBUILD_DLLS = 'AUTOREBUILD_DLLS';
  PREFS_KEEP_AUDIO = 'KEEP_AUDIO';
  PREFS_AUTO_LOCATE_TO_ACTIVE_TEXT = 'AUTO_LOCATE_TO_ACTIVE_TEXT';

  // ----- Project script variables -----
  PV_ACTIVE_CONFIG = 'ACTIVE_CONFIG'; // Active config in the Compofiller Studio GUI

  PV_PROJECT_INFO_FILE = 'PROJECT_INFO_FILE';
  PV_PROJECT_SCREENSHOT = 'PROJECT_SCREENSHOT';


  // ----- Config script variables -----
  CV_PARENT_CONFIG = 'PARENT_CONFIG';

  // Config / timeline
  // Project content related variables
  CV_TIME_BASE = 'TIME_BASE';

  // loop settings are only for the IDE and they don't affect the compiled end-product
  CV_LOOP_START = 'LOOP_START';
  CV_LOOP_END = 'LOOP_END';
  CV_LOOP_ENABLED = 'LOOP_ENABLED';

  // Config / music
  CV_MUSIC_4KLANG_INC_FILE = 'MUSIC_4KLANG_INC_FILE';

  // Beats per bar is for calculating bars from the 4klang music file
  CV_MUSIC_BEATS_PER_BAR = 'MUSIC_BEATS_PER_BAR';

  CV_PROD_END_TIME = 'PROD_END_TIME';

  // Config / visuals
  CV_SHADER_FILE = 'SHADER_FILE';
  CV_USE_TIME_UNIFORM = 'USE_TIME_UNIFORM';
  CV_TIME_UNIFORM_NAME = 'TIME_UNIFORM_NAME';
  CV_USE_RESOLUTION_UNIFORM = 'USE_RESOLUTION_UNIFORM';
  CV_RESOLUTION_UNIFORM_NAME = 'RESOLUTION_UNIFORM_NAME';

  CV_AUDIO_BUFFER_ALLOCATED_LENGTH = 'AUDIO_BUFFER_ALLOCATED_LENGTH'; // in samples
  CV_AUDIO_DELAY = 'AUDIO_DELAY'; // i.e. delay, in samples
  CV_AUDIO_SAMPLING_RATE = 'AUDIO_SAMPLING_RATE';

  CV_TIME_DIVIDER = 'TIME_DIVIDER';
  CV_TIME_DIVIDER_INT = 'TIME_DIVIDER_INT'; // truncated integer version of TIME_DIVIDER
  CV_USE_TIME_DIVIDER_IN_X86_CODE = 'USE_TIME_DIVIDER_IN_X86_CODE';

  CV_RESOLUTION_X = 'RESOLUTION_X';
  CV_RESOLUTION_Y = 'RESOLUTION_Y';

  CV_TWO_PASS_RENDERING = 'TWO_PASS_RENDERING';
  CV_FRAME_TO_TEXTURE = 'FRAME_TO_TEXTURE';
  CV_USE_MIPMAP = 'USE_MIPMAP';
  CV_SECOND_PASS_NEGATIVE_TIME = 'SECOND_PASS_NEGATIVE_TIME';


  CV_USE_TEXTS = 'USE_TEXTS';
  CV_USE_TEXTS_UNIFORM = 'USE_TEXTS_UNIFORM';
  CV_TEXTS_UNIFORM_NAME = 'TEXTS_UNIFORM_NAME';
  CV_TEXT_BITMAP_RESOLUTION_X = 'TEXT_BITMAP_RESOLUTION_X';
  CV_TEXT_BITMAP_RESOLUTION_Y = 'TEXT_BITMAP_RESOLUTION_Y';
  CV_TEXT_FONT_NAME = 'TEXT_FONT_NAME';
  CV_TEXT_FONT_SIZE = 'TEXT_FONT_SIZE';
  CV_TEXT_FONT_STRIKEOUT = 'TEXT_FONT_STRIKEOUT';
  CV_TEXT_FONT_UNDERLINE = 'TEXT_FONT_UNDERLINE';
  CV_TEXT_FONT_ITALIC = 'TEXT_FONT_ITALIC';
  CV_TEXT_FONT_WEIGHT = 'TEXT_FONT_WEIGHT';
  CV_TEXT_FONT_ORIENTATION = 'TEXT_FONT_ORIENTATION';
  CV_TEXT_FONT_ESCAPEMENT = 'TEXT_FONT_ESCAPEMENT';
  CV_TEXT_FONT_WIDTH = 'TEXT_FONT_WIDTH';
  CV_TEXT_CHARACTER_EXTRA_SPACING = 'TEXT_CHARACTER_EXTRA_SPACING';
  CV_USE_WIDECHAR_TEXTS = 'USE_WIDECHAR_TEXTS';


  // Config / Linker
  CV_EXE_LINKER_PROGRAM = 'EXE_LINKER_PROGRAM';
  CV_OUTPUT_EXE_NAME = 'OUTPUT_EXE_NAME';

  // Config / Linker / Crinkler
  CV_CRINKLER_ORDERTRIES = 'CRINKLER_ORDERTRIES';


  // ----- Build script variables -----
  BV_PROGRAM_DIR = 'PROGRAM_DIR'; // Where CompofillerStudio.exe is
  BV_PROJECT_DIR = 'PROJECT_DIR'; // Where all the project files are, including PROJECT_FILE
  BV_PROJECT_FILE = 'PROJECT_FILE'; // What project file to build
  BV_CONFIG_FILE = 'CONFIG_FILE'; // What config to build

  // These are used e.g. by MinifyShader.script
  BV_SOURCE_FILE = 'SOURCE_FILE';
  BV_DESTINATION_FILE = 'DESTINATION_FILE';


implementation

end.
