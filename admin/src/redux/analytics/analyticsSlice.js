import { createSlice } from "@reduxjs/toolkit";
import { fetchAnalytics } from "./analyticsThunks";

const initialState = {
    bookingData: [],
    revenueData: [],
    userData: [],
    userGrowthData: [],
    venueGrowthData: [],
    bookingTrendData: [],
    monthlyRevenueData: [],
    revenueByVenueData: [],
    revenueBySportData: [],
    mostPlayedSportsData: [],
    mostBookedVenuesData: [],
    peakBookingHoursData: [],
    topUsersByBookingsData: [],
    mostLikedPostsData: [],
    topContentCreatorsData: [],
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

export const analyticsSlice = createSlice({
    name: "analytics",
    initialState,
    reducers: {
        clearAnalyticsError: (state) => {
            state.error = null;
        },
    },
    extraReducers: (builder) => {
        builder
            .addCase(fetchAnalytics.pending, setPending)
            .addCase(fetchAnalytics.fulfilled, (state, action) => {
                state.status = "succeeded";
                Object.assign(state, action.payload);
            })
            .addCase(fetchAnalytics.rejected, setRejected);
    },
});

export const { clearAnalyticsError } = analyticsSlice.actions;
export default analyticsSlice.reducer;
