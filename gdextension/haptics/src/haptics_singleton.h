#ifndef HAPTICS_SINGLETON_H
#define HAPTICS_SINGLETON_H

#include <godot_cpp/classes/object.hpp>
#include <godot_cpp/core/class_db.hpp>

namespace godot {

class DaxtleHaptics : public Object {
    GDCLASS(DaxtleHaptics, Object);

protected:
    static void _bind_methods();

public:
    DaxtleHaptics();
    ~DaxtleHaptics();

    void tap_light();
    void notify_success();
    void notify_error();
};

}

#endif
