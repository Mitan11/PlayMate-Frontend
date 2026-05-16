import { createSlice } from "@reduxjs/toolkit";
import { fetchVenues, removeVenue } from "./venuesThunks";

const initialState = {
    venues: [],
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

export const venuesSlice = createSlice({
    name: "venues",
    initialState,
    reducers: {
        clearVenuesError: (state) => {
            state.error = null;
        },
    },
    extraReducers: (builder) => {
        builder
            .addCase(fetchVenues.pending, setPending)
            .addCase(fetchVenues.fulfilled, (state, action) => {
                state.status = "succeeded";
                state.venues = action.payload;
            })
            .addCase(fetchVenues.rejected, setRejected)
            .addCase(removeVenue.pending, setPending)
            .addCase(removeVenue.fulfilled, (state, action) => {
                state.status = "succeeded";
                state.venues = state.venues.filter((venue) => venue.venue_id !== action.payload);
            })
            .addCase(removeVenue.rejected, setRejected);
    },
});

export const { clearVenuesError } = venuesSlice.actions;
export default venuesSlice.reducer;
