import { createSlice } from "@reduxjs/toolkit";
import { fetchDashboardData } from "./dashboardThunks";

const initialState = {
    stats: null,
    sportMetrics: [],
    recentActivities: [],
    status: "idle",
    error: null,
};

const setPending = (state) => {
    state.status = "loading";
    state.error = null;
};

const setRejected = (state, action) => {
    state.status = "failed";
    state.error = action.payload || action.error?.message || "Something went wrong";
};

export const dashboardSlice = createSlice({
    name: "dashboard",
    initialState,
    reducers: {
        clearDashboardError: (state) => {
            state.error = null;
        },
    },
    extraReducers: (builder) => {
        builder
            .addCase(fetchDashboardData.pending, setPending)
            .addCase(fetchDashboardData.fulfilled, (state, action) => {
                state.status = "succeeded";
                state.stats = action.payload.stats;
                state.sportMetrics = action.payload.sportMetrics;
                state.recentActivities = action.payload.recentActivities;
            })
            .addCase(fetchDashboardData.rejected, setRejected);
    },
});

export const { clearDashboardError } = dashboardSlice.actions;
export default dashboardSlice.reducer;
