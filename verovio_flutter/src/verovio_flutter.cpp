// verovio_flutter.cpp - REAL Verovio C++ implementation for Flutter
// This replaces the previous mock implementation with actual Verovio functionality

#include "verovio_flutter.h"
#include <vrv/toolkit.h>
#include <string>
#include <memory>
#include <cstring>
#include <cstdlib>

#ifdef ANDROID
#include <android/log.h>
#define LOGD(...) __android_log_print(ANDROID_LOG_DEBUG, "VerovioFlutter", __VA_ARGS__)
#define LOGE(...) __android_log_print(ANDROID_LOG_ERROR, "VerovioFlutter", __VA_ARGS__)
#else
#define LOGD(...) printf(__VA_ARGS__)
#define LOGE(...) fprintf(stderr, __VA_ARGS__)
#endif

// Global Verovio toolkit instance
static std::unique_ptr<vrv::Toolkit> g_verovio_toolkit = nullptr;

// Static buffers for string returns (C FFI requirement)
static char g_svg_buffer[500000];      // 500KB for large SVGs
static char g_result_buffer[16000];    // For JSON results, version info, etc.
static char g_midi_buffer[32000];      // For MIDI data

// Helper function to copy string to static buffer
static const char* copy_to_buffer(const std::string& str, char* buffer, size_t buffer_size) {
    if (str.empty()) {
        buffer[0] = '\0';
        return buffer;
    }

    size_t copy_len = std::min(str.length(), buffer_size - 1);
    strncpy(buffer, str.c_str(), copy_len);
    buffer[copy_len] = '\0';
    return buffer;
}

extern "C" {

FFI_PLUGIN_EXPORT int verovio_initialize(void) {
    LOGD("🚀 VEROVIO REAL: Initializing Verovio C++ engine");

    try {
        // Create new Verovio toolkit instance
        g_verovio_toolkit = std::make_unique<vrv::Toolkit>();

        if (!g_verovio_toolkit) {
            LOGE("❌ VEROVIO REAL: Failed to create Verovio toolkit");
            return 0;
        }

        // Clear all buffers
        g_svg_buffer[0] = '\0';
        g_result_buffer[0] = '\0';
        g_midi_buffer[0] = '\0';

        LOGD("✅ VEROVIO REAL: Successfully initialized with toolkit");
        return 1;

    } catch (const std::exception& e) {
        LOGE("❌ VEROVIO REAL: Exception during initialization: %s", e.what());
        return 0;
    } catch (...) {
        LOGE("❌ VEROVIO REAL: Unknown exception during initialization");
        return 0;
    }
}

FFI_PLUGIN_EXPORT int verovio_set_options(const char* options_json) {
    LOGD("🔧 VEROVIO REAL: Setting options: %s", options_json ? options_json : "null");

    if (!g_verovio_toolkit) {
        LOGE("❌ VEROVIO REAL: Toolkit not initialized");
        return 0;
    }

    if (!options_json) {
        LOGE("❌ VEROVIO REAL: Null options JSON");
        return 0;
    }

    try {
        std::string options(options_json);
        bool success = g_verovio_toolkit->SetOptions(options);

        if (success) {
            LOGD("✅ VEROVIO REAL: Options set successfully");
        } else {
            LOGE("❌ VEROVIO REAL: Failed to set options");
        }

        return success ? 1 : 0;

    } catch (const std::exception& e) {
        LOGE("❌ VEROVIO REAL: Exception setting options: %s", e.what());
        return 0;
    } catch (...) {
        LOGE("❌ VEROVIO REAL: Unknown exception setting options");
        return 0;
    }
}

FFI_PLUGIN_EXPORT int verovio_load_data(const char* musicxml) {
    LOGD("📄 VEROVIO REAL: Loading MusicXML data (%zu chars)",
         musicxml ? strlen(musicxml) : 0);

    if (!g_verovio_toolkit) {
        LOGE("❌ VEROVIO REAL: Toolkit not initialized");
        return 0;
    }

    if (!musicxml) {
        LOGE("❌ VEROVIO REAL: Null MusicXML data");
        return 0;
    }

    try {
        std::string data(musicxml);
        bool success = g_verovio_toolkit->LoadData(data);

        if (success) {
            LOGD("✅ VEROVIO REAL: MusicXML loaded successfully");
        } else {
            LOGE("❌ VEROVIO REAL: Failed to load MusicXML");
        }

        return success ? 1 : 0;

    } catch (const std::exception& e) {
        LOGE("❌ VEROVIO REAL: Exception loading data: %s", e.what());
        return 0;
    } catch (...) {
        LOGE("❌ VEROVIO REAL: Unknown exception loading data");
        return 0;
    }
}

FFI_PLUGIN_EXPORT const char* verovio_render_to_svg(int page_number) {
    LOGD("🎨 VEROVIO REAL: Rendering page %d to SVG", page_number);

    if (!g_verovio_toolkit) {
        LOGE("❌ VEROVIO REAL: Toolkit not initialized");
        strcpy(g_svg_buffer, "<svg xmlns=\"http://www.w3.org/2000/svg\"><text>Error: Not initialized</text></svg>");
        return g_svg_buffer;
    }

    try {
        std::string svg = g_verovio_toolkit->RenderToSVG(page_number);

        if (svg.empty()) {
            LOGE("❌ VEROVIO REAL: Empty SVG returned");
            strcpy(g_svg_buffer, "<svg xmlns=\"http://www.w3.org/2000/svg\"><text>Error: Empty SVG</text></svg>");
            return g_svg_buffer;
        }

        LOGD("✅ VEROVIO REAL: SVG rendered successfully (%zu chars)", svg.length());
        return copy_to_buffer(svg, g_svg_buffer, sizeof(g_svg_buffer));

    } catch (const std::exception& e) {
        LOGE("❌ VEROVIO REAL: Exception rendering SVG: %s", e.what());
        sprintf(g_svg_buffer, "<svg xmlns=\"http://www.w3.org/2000/svg\"><text>Error: %s</text></svg>", e.what());
        return g_svg_buffer;
    } catch (...) {
        LOGE("❌ VEROVIO REAL: Unknown exception rendering SVG");
        strcpy(g_svg_buffer, "<svg xmlns=\"http://www.w3.org/2000/svg\"><text>Error: Unknown exception</text></svg>");
        return g_svg_buffer;
    }
}

FFI_PLUGIN_EXPORT int verovio_get_page_count(void) {
    LOGD("📊 VEROVIO REAL: Getting page count");

    if (!g_verovio_toolkit) {
        LOGE("❌ VEROVIO REAL: Toolkit not initialized");
        return 0;
    }

    try {
        int count = g_verovio_toolkit->GetPageCount();
        LOGD("✅ VEROVIO REAL: Page count: %d", count);
        return count;

    } catch (const std::exception& e) {
        LOGE("❌ VEROVIO REAL: Exception getting page count: %s", e.what());
        return 0;
    } catch (...) {
        LOGE("❌ VEROVIO REAL: Unknown exception getting page count");
        return 0;
    }
}

FFI_PLUGIN_EXPORT const char* verovio_get_element_attr(const char* xml_id) {
    LOGD("🔍 VEROVIO REAL: Getting element attributes for ID: %s", xml_id ? xml_id : "null");

    if (!g_verovio_toolkit) {
        LOGE("❌ VEROVIO REAL: Toolkit not initialized");
        strcpy(g_result_buffer, "{}");
        return g_result_buffer;
    }

    if (!xml_id) {
        LOGE("❌ VEROVIO REAL: Null XML ID");
        strcpy(g_result_buffer, "{}");
        return g_result_buffer;
    }

    try {
        std::string id(xml_id);
        std::string attrs = g_verovio_toolkit->GetElementAttr(id);

        LOGD("✅ VEROVIO REAL: Element attributes retrieved");
        return copy_to_buffer(attrs, g_result_buffer, sizeof(g_result_buffer));

    } catch (const std::exception& e) {
        LOGE("❌ VEROVIO REAL: Exception getting element attributes: %s", e.what());
        strcpy(g_result_buffer, "{}");
        return g_result_buffer;
    } catch (...) {
        LOGE("❌ VEROVIO REAL: Unknown exception getting element attributes");
        strcpy(g_result_buffer, "{}");
        return g_result_buffer;
    }
}

FFI_PLUGIN_EXPORT const char* verovio_get_elements_at_time(int time_ms) {
    LOGD("⏰ VEROVIO REAL: Getting elements at time: %d ms", time_ms);

    if (!g_verovio_toolkit) {
        LOGE("❌ VEROVIO REAL: Toolkit not initialized");
        strcpy(g_result_buffer, "[]");
        return g_result_buffer;
    }

    try {
        std::string elements = g_verovio_toolkit->GetElementsAtTime(time_ms);

        LOGD("✅ VEROVIO REAL: Elements at time retrieved");
        return copy_to_buffer(elements, g_result_buffer, sizeof(g_result_buffer));

    } catch (const std::exception& e) {
        LOGE("❌ VEROVIO REAL: Exception getting elements at time: %s", e.what());
        strcpy(g_result_buffer, "[]");
        return g_result_buffer;
    } catch (...) {
        LOGE("❌ VEROVIO REAL: Unknown exception getting elements at time");
        strcpy(g_result_buffer, "[]");
        return g_result_buffer;
    }
}

FFI_PLUGIN_EXPORT const char* verovio_render_to_midi(void) {
    LOGD("🎵 VEROVIO REAL: Rendering to MIDI");

    if (!g_verovio_toolkit) {
        LOGE("❌ VEROVIO REAL: Toolkit not initialized");
        g_midi_buffer[0] = '\0';
        return g_midi_buffer;
    }

    try {
        std::string midi = g_verovio_toolkit->RenderToMIDI();

        LOGD("✅ VEROVIO REAL: MIDI rendered successfully (%zu bytes)", midi.length());
        return copy_to_buffer(midi, g_midi_buffer, sizeof(g_midi_buffer));

    } catch (const std::exception& e) {
        LOGE("❌ VEROVIO REAL: Exception rendering MIDI: %s", e.what());
        g_midi_buffer[0] = '\0';
        return g_midi_buffer;
    } catch (...) {
        LOGE("❌ VEROVIO REAL: Unknown exception rendering MIDI");
        g_midi_buffer[0] = '\0';
        return g_midi_buffer;
    }
}

FFI_PLUGIN_EXPORT int verovio_validate_musicxml(const char* musicxml) {
    LOGD("✅ VEROVIO REAL: Validating MusicXML (%zu chars)",
         musicxml ? strlen(musicxml) : 0);

    if (!g_verovio_toolkit) {
        LOGE("❌ VEROVIO REAL: Toolkit not initialized");
        return 0;
    }

    if (!musicxml) {
        LOGE("❌ VEROVIO REAL: Null MusicXML data");
        return 0;
    }

    try {
        std::string data(musicxml);
        // Simplified validation - just try to load the data
        bool valid = g_verovio_toolkit->LoadData(data);

        LOGD("✅ VEROVIO REAL: MusicXML validation: %s", valid ? "VALID" : "INVALID");
        return valid ? 1 : 0;

    } catch (const std::exception& e) {
        LOGE("❌ VEROVIO REAL: Exception validating MusicXML: %s", e.what());
        return 0;
    } catch (...) {
        LOGE("❌ VEROVIO REAL: Unknown exception validating MusicXML");
        return 0;
    }
}

FFI_PLUGIN_EXPORT const char* verovio_convert_file(const char* data, const char* from_format) {
    LOGD("🔄 VEROVIO REAL: Converting file from format: %s", from_format ? from_format : "null");

    if (!g_verovio_toolkit) {
        LOGE("❌ VEROVIO REAL: Toolkit not initialized");
        g_result_buffer[0] = '\0';
        return g_result_buffer;
    }

    if (!data || !from_format) {
        LOGE("❌ VEROVIO REAL: Null data or format");
        g_result_buffer[0] = '\0';
        return g_result_buffer;
    }

    try {
        std::string input_data(data);
        std::string format(from_format);

        // Load data and convert to MusicXML
        bool loaded = g_verovio_toolkit->LoadData(input_data);
        if (!loaded) {
            LOGE("❌ VEROVIO REAL: Failed to load data for conversion");
            g_result_buffer[0] = '\0';
            return g_result_buffer;
        }

        std::string converted = g_verovio_toolkit->GetMEI();

        LOGD("✅ VEROVIO REAL: File converted successfully");
        return copy_to_buffer(converted, g_result_buffer, sizeof(g_result_buffer));

    } catch (const std::exception& e) {
        LOGE("❌ VEROVIO REAL: Exception converting file: %s", e.what());
        g_result_buffer[0] = '\0';
        return g_result_buffer;
    } catch (...) {
        LOGE("❌ VEROVIO REAL: Unknown exception converting file");
        g_result_buffer[0] = '\0';
        return g_result_buffer;
    }
}

FFI_PLUGIN_EXPORT void verovio_cleanup(void) {
    LOGD("🧹 VEROVIO REAL: Cleaning up resources");

    try {
        // Reset the toolkit
        g_verovio_toolkit.reset();

        // Clear all buffers
        g_svg_buffer[0] = '\0';
        g_result_buffer[0] = '\0';
        g_midi_buffer[0] = '\0';

        LOGD("✅ VEROVIO REAL: Cleanup completed successfully");

    } catch (const std::exception& e) {
        LOGE("❌ VEROVIO REAL: Exception during cleanup: %s", e.what());
    } catch (...) {
        LOGE("❌ VEROVIO REAL: Unknown exception during cleanup");
    }
}

FFI_PLUGIN_EXPORT const char* verovio_get_version(void) {
    LOGD("ℹ️ VEROVIO REAL: Getting Verovio version");

    try {
        if (!g_verovio_toolkit) {
            // Even without toolkit, we can return the version
            strcpy(g_result_buffer, "4.3.1-real");
            return g_result_buffer;
        }

        std::string version = g_verovio_toolkit->GetVersion();

        LOGD("✅ VEROVIO REAL: Version: %s", version.c_str());
        return copy_to_buffer(version, g_result_buffer, sizeof(g_result_buffer));

    } catch (const std::exception& e) {
        LOGE("❌ VEROVIO REAL: Exception getting version: %s", e.what());
        strcpy(g_result_buffer, "4.3.1-real-error");
        return g_result_buffer;
    } catch (...) {
        LOGE("❌ VEROVIO REAL: Unknown exception getting version");
        strcpy(g_result_buffer, "4.3.1-real-unknown");
        return g_result_buffer;
    }
}

} // extern "C"