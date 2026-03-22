#include "register_types.h"
#include "haptics_singleton.h"

#include <gdextension_interface.h>
#include <godot_cpp/core/defs.hpp>
#include <godot_cpp/godot.hpp>
#include <godot_cpp/classes/engine.hpp>

using namespace godot;

static DaxtleHaptics *_haptics_singleton = nullptr;

void initialize_haptics_module(ModuleInitializationLevel p_level) {
    if (p_level != MODULE_INITIALIZATION_LEVEL_SCENE) {
        return;
    }
    ClassDB::register_class<DaxtleHaptics>();
    _haptics_singleton = memnew(DaxtleHaptics);
    Engine::get_singleton()->register_singleton("DaxtleHaptics", _haptics_singleton);
}

void uninitialize_haptics_module(ModuleInitializationLevel p_level) {
    if (p_level != MODULE_INITIALIZATION_LEVEL_SCENE) {
        return;
    }
    Engine::get_singleton()->unregister_singleton("DaxtleHaptics");
    memdelete(_haptics_singleton);
}

extern "C" {
GDExtensionBool GDE_EXPORT haptics_init(
    GDExtensionInterfaceGetProcAddress p_get_proc_address,
    const GDExtensionClassLibraryPtr p_library,
    GDExtensionInitialization *r_initialization
) {
    godot::GDExtensionBinding::InitObject init_obj(p_get_proc_address, p_library, r_initialization);
    init_obj.register_initializer(initialize_haptics_module);
    init_obj.register_terminator(uninitialize_haptics_module);
    init_obj.set_minimum_library_initialization_level(MODULE_INITIALIZATION_LEVEL_SCENE);
    return init_obj.init();
}
}
