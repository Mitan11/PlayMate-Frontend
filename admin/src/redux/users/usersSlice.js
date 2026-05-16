import { createSlice } from "@reduxjs/toolkit";
import { fetchUsers, removeUser } from "./usersThunks";

const initialState = {
    users: [],
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

export const usersSlice = createSlice({
    name: "users",
    initialState,
    reducers: {
        clearUsersError: (state) => {
            state.error = null;
        },
    },
    extraReducers: (builder) => {
        builder
            .addCase(fetchUsers.pending, setPending)
            .addCase(fetchUsers.fulfilled, (state, action) => {
                state.status = "succeeded";
                state.users = action.payload;
            })
            .addCase(fetchUsers.rejected, setRejected)
            .addCase(removeUser.pending, setPending)
            .addCase(removeUser.fulfilled, (state, action) => {
                state.status = "succeeded";
                state.users = state.users.filter((user) => user.user_id !== action.payload);
            })
            .addCase(removeUser.rejected, setRejected);
    },
});

export const { clearUsersError } = usersSlice.actions;
export default usersSlice.reducer;
