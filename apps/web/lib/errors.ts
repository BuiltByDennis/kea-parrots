// Kea Parrot — API error envelope helpers (Product P0 scaffold).
// Envelope per KEA-API-004 §5.3: never raw DB errors, stack traces,
// service-role keys, passwords, or unnecessary sensitive data.

export type ApiErrorBody = {
  success: false;
  error: { code: string; message: string; details: string[] };
  meta: { requestId: string };
};

export type ApiSuccessBody<T> = {
  success: true;
  data: T;
  meta: { requestId: string };
};

export function errorBody(
  code: string,
  message: string,
  requestId: string,
  details: string[] = [],
): ApiErrorBody {
  return { success: false, error: { code, message, details }, meta: { requestId } };
}

export function successBody<T>(data: T, requestId: string): ApiSuccessBody<T> {
  return { success: true, data, meta: { requestId } };
}
