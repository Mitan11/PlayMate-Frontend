import { createSlice } from "@reduxjs/toolkit";
import { addSport, deleteSport, fetchSports, updateSport } from "./sportsThunks";

const initialState = {
	sports: [],
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

export const sportsSlice = createSlice({
	name: "sports",
	initialState,
	reducers: {
		clearSportsError: (state) => {
			state.error = null;
		},
	},
	extraReducers: (builder) => {
		builder
			.addCase(fetchSports.pending, setPending)
			.addCase(fetchSports.fulfilled, (state, action) => {
				state.status = "succeeded";
				state.sports = action.payload;
			})
			.addCase(fetchSports.rejected, setRejected)
			.addCase(addSport.pending, setPending)
			.addCase(addSport.fulfilled, (state) => {
				state.status = "succeeded";
			})
			.addCase(addSport.rejected, setRejected)
			.addCase(updateSport.pending, setPending)
			.addCase(updateSport.fulfilled, (state) => {
				state.status = "succeeded";
			})
			.addCase(updateSport.rejected, setRejected)
			.addCase(deleteSport.pending, setPending)
			.addCase(deleteSport.fulfilled, (state) => {
				state.status = "succeeded";
			})
			.addCase(deleteSport.rejected, setRejected);
	},
});

export const { clearSportsError } = sportsSlice.actions;
export default sportsSlice.reducer;
