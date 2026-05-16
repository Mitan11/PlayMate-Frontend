import { createAsyncThunk } from "@reduxjs/toolkit";
import { venuesApi } from "./venuesApi";

const getToken = (state) => state.auth.token;

export const fetchVenues = createAsyncThunk(
    "venues/fetchVenues",
    async (_, { getState, rejectWithValue }) => {
        try {
            const token = getToken(getState());
            const data = await venuesApi.fetchVenues(token);
            return data.data || [];
        } catch (error) {
            return rejectWithValue(error?.response?.data?.message || "Failed to fetch venues");
        }
    }
);

export const removeVenue = createAsyncThunk(
    "venues/removeVenue",
    async (venueId, { getState, rejectWithValue }) => {
        try {
            const token = getToken(getState());
            await venuesApi.deleteVenue(token, venueId);
            return venueId;
        } catch (error) {
            return rejectWithValue(error?.response?.data?.message || "Failed to delete venue");
        }
    }
);
