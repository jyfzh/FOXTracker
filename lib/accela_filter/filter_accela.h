  
/* Copyright (c) 2012-2015 Stanislaw Halik
 *
 * Permission to use, copy, modify, and/or distribute this software for any
 * purpose with or without fee is hereby granted, provided that the above
 * copyright notice and this permission notice appear in all copies.
 */
#pragma once

#include <accela-settings.hpp>

// Keep the filter boundary independent of Eigen.  Eigen is header-only and
// different targets can otherwise select different versions for these values.
struct accela_state
{
    double eul[3] {};
    double translation[3] {};
};

enum Axis : int
{
    NonAxis = -1,
    TX = 0, TY = 1, TZ = 2,

    Yaw = 3, Pitch = 4, Roll = 5,
    Axis_MIN = TX, Axis_MAX = 5,

    Axis_COUNT = 6,
};


struct accela
{
    accela(settings_accela * _s);
    void filter(const accela_state &input, double dt, accela_state &output);
    void center() { first_run = true; }
private:
    settings_accela * s = nullptr;
    double last_output[6] {}, deltas[6] {};
    bool first_run = true;
};
