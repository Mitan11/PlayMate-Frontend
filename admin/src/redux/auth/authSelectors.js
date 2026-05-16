export const selectAuthUser = (state) => state.auth.adminUser;
export const selectAuthStatus = (state) => state.auth.status;
export const selectAuthError = (state) => state.auth.error;
export const selectAuthToken = (state) => state.auth.token;
export const selectIsAuthenticated = (state) => !!state.auth.token;
