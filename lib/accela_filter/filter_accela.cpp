  
/* Copyright (c) 2012-2016 Stanislaw Halik
 *
 * Permission to use, copy, modify, and/or distribute this software for any
 * purpose with or without fee is hereby granted, provided that the above
 * copyright notice and this permission notice appear in all copies->
 */
#include <cmath>
#include <filter_accela.h>

namespace {

double clamp(double value, double minimum, double maximum)
{
    if (value < minimum)
        return minimum;
    if (value > maximum)
        return maximum;
    return value;
}

int signum(double value)
{
    return value < 0.0 ? -1 : 1;
}

} // namespace

accela::accela(settings_accela * _s): s(_s) {}

template<typename F>
static void do_deltas(const double* deltas, double* output, F&& fun)
{
    constexpr unsigned N = 3;

    double norm[N];
    double dist = 0;

    for (unsigned k = 0; k < N; k++)
        dist += deltas[k]*deltas[k];
    dist = sqrt(dist);

    const double value = fun(dist);

    for (unsigned k = 0; k < N; k++)
    {
        const double c = dist > 1e-6 ? clamp((fabs(deltas[k]) / dist), 0., 1.) : 0;
        norm[k] = c;
    }

    double n = 0;
    for (unsigned k = 0; k < N; k++) // NOLINT(modernize-loop-convert)
        n += norm[k];

    if (n > 1e-6)
    {
        const double ret = 1./n;
        for (unsigned k = 0; k < N; k++) // NOLINT(modernize-loop-convert)
            norm[k] *= ret;
    }
    else
        for (unsigned k = 0; k < N; k++) // NOLINT(modernize-loop-convert)
            norm[k] = 0;

    for (unsigned k = 0; k < N; k++)
    {
        const double d = norm[k] * value;
        output[k] = signum(deltas[k]) * d;
    }
}

void accela::filter(const accela_state &state, double dt, accela_state &result)
{
    double input[6] = {0};
    double output[6] = {0};

    input[TX] = state.translation[0];
    input[TY] = state.translation[1];
    input[TZ] = state.translation[2];
    input[Yaw] = state.eul[0];
    input[Pitch] = state.eul[1];
    input[Roll] = state.eul[2];

    static constexpr double full_turn = 360.0;	
    static constexpr double half_turn = 180.0;	

    if (first_run)
    {
        first_run = false;

        for (int i = 0; i < 6; i++)
        {
            const double f = input[i];
            output[i] = f;
            last_output[i] = f;
        }

        for (unsigned i = 0; i < 3; ++i)
        {
            result.eul[i] = input[Yaw + i];
            result.translation[i] = input[TX + i];
        }
        return;
    }

    const double rot_thres{s->rot_smoothing};
    const double pos_thres{s->pos_smoothing};


    const double rot_dz{ s->rot_deadzone};
    const double pos_dz{ s->pos_deadzone};

    // rot

    for (unsigned i = 3; i < 6; i++)
    {
        double d = input[i] - last_output[i];
        if (fabs(d) > half_turn) d -= copysign(full_turn, d);

        if (fabs(d) > rot_dz)
            d -= copysign(rot_dz, d);
        else
            d = 0;

        deltas[i] = d / rot_thres;
    }

    do_deltas(&deltas[Yaw], &output[Yaw], [this](double x) {
        // return spline_rot.get_value_no_save(x);
        return x;
    });

    // pos

    for (unsigned i = 0; i < 3; i++)
    {
        double d = input[i] - last_output[i];
        if (fabs(d) > pos_dz)
            d -= copysign(pos_dz, d);
        else
            d = 0;

        deltas[i] = d / pos_thres;
    }

    do_deltas(&deltas[TX], &output[TX], [this](double x) {
        // return spline_pos->get_value_no_save(x);
        return x;
    });

    // end

    for (unsigned k = 0; k < 6; k++)
    {
        output[k] *= dt;
        output[k] += last_output[k];
        if (fabs(output[k]) > half_turn) output[k] -= copysign(full_turn, output[k]);

        last_output[k] = output[k];
    }

    for (unsigned i = 0; i < 3; ++i)
    {
        result.eul[i] = output[Yaw + i];
        result.translation[i] = output[TX + i];
    }
}
