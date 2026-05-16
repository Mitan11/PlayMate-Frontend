import { createAsyncThunk } from "@reduxjs/toolkit";
import { sportsApi } from "./sportsApi";

const getToken = (state) => state.auth.token;

export const fetchSports = createAsyncThunk(
	"sports/fetchSports",
	async (_, { getState, rejectWithValue }) => {
		try {
			const token = getToken(getState());
			const data = await sportsApi.fetchSports(token);
			return data.data || [];
		} catch (error) {
			return rejectWithValue(error?.response?.data?.message || "Failed to fetch sports");
		}
	}
);

export const addSport = createAsyncThunk(
	"sports/addSport",
	async (sportName, { getState, rejectWithValue }) => {
		try {
			const token = getToken(getState());
			await sportsApi.addSport(token, sportName);
			return true;
		} catch (error) {
			return rejectWithValue(error?.response?.data?.message || "Failed to add sport");
		}
	}
);

export const updateSport = createAsyncThunk(
	"sports/updateSport",
	async ({ sportId, sportName }, { getState, rejectWithValue }) => {
		try {
			const token = getToken(getState());
			await sportsApi.updateSport(token, sportId, sportName);
			return true;
		} catch (error) {
			return rejectWithValue(error?.response?.data?.message || "Failed to update sport");
		}
	}
);

export const deleteSport = createAsyncThunk(
	"sports/deleteSport",
	async (sportId, { getState, rejectWithValue }) => {
		try {
			const token = getToken(getState());
			await sportsApi.deleteSport(token, sportId);
			return true;
		} catch (error) {
			return rejectWithValue(error?.response?.data?.message || "Failed to delete sport");
		}
	}
);
