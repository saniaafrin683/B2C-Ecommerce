package com.example.myshop;

import android.app.Activity;
import android.content.Intent;
import android.net.Uri;
import android.util.Log;
import android.widget.Toast;

import androidx.core.content.FileProvider;

import com.example.myshop.network.RetrofitClient;
import com.example.myshop.storage.SessionManager;

import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;

import okhttp3.ResponseBody;
import retrofit2.Call;
import retrofit2.Callback;
import retrofit2.Response;

public final class InvoiceOpener {
    private static final String TAG = "InvoiceOpener";

    private InvoiceOpener() {
    }

    public static void open(Activity activity, SessionManager sessionManager, long orderId) {
        if (orderId <= 0) {
            Toast.makeText(activity, "Invoice is not available yet.", Toast.LENGTH_SHORT).show();
            return;
        }

        RetrofitClient.getApiService()
                .downloadMyOrderInvoice("Bearer " + sessionManager.getToken(), orderId)
                .enqueue(new Callback<ResponseBody>() {
                    @Override
                    public void onResponse(Call<ResponseBody> call, Response<ResponseBody> response) {
                        Log.i(TAG, "Invoice response orderId=" + orderId
                                + " code=" + response.code()
                                + " successful=" + response.isSuccessful()
                                + " contentType=" + (response.body() == null ? null : response.body().contentType())
                                + " contentLength=" + (response.body() == null ? -1 : response.body().contentLength()));
                        if (!response.isSuccessful() || response.body() == null) {
                            Log.w(TAG, "Invoice unavailable orderId=" + orderId + " code=" + response.code());
                            Toast.makeText(activity, "Invoice is not available yet.", Toast.LENGTH_SHORT).show();
                            return;
                        }
                        try {
                            File file = saveInvoice(activity, orderId, response.body());
                            openPdf(activity, file);
                        } catch (IOException ex) {
                            Log.e(TAG, "Invoice PDF save/open failed orderId=" + orderId, ex);
                            Toast.makeText(activity, "Unable to open invoice.", Toast.LENGTH_SHORT).show();
                        }
                    }

                    @Override
                    public void onFailure(Call<ResponseBody> call, Throwable throwable) {
                        Log.e(TAG, "Invoice download failed orderId=" + orderId, throwable);
                        Toast.makeText(activity, "Unable to download invoice.", Toast.LENGTH_SHORT).show();
                    }
                });
    }

    private static File saveInvoice(Activity activity, long orderId, ResponseBody body) throws IOException {
        File directory = new File(activity.getCacheDir(), "invoices");
        if (!directory.exists() && !directory.mkdirs()) {
            throw new IOException("Invoice cache directory could not be created.");
        }

        File file = new File(directory, "invoice-" + orderId + ".pdf");
        try (InputStream inputStream = body.byteStream();
             FileOutputStream outputStream = new FileOutputStream(file)) {
            byte[] buffer = new byte[8192];
            int read;
            while ((read = inputStream.read(buffer)) != -1) {
                outputStream.write(buffer, 0, read);
            }
        }
        return file;
    }

    private static void openPdf(Activity activity, File file) {
        Uri uri = FileProvider.getUriForFile(activity, activity.getPackageName() + ".fileprovider", file);
        Intent intent = new Intent(Intent.ACTION_VIEW);
        intent.setDataAndType(uri, "application/pdf");
        intent.addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION);
        try {
            activity.startActivity(intent);
        } catch (Exception ex) {
            Toast.makeText(activity, "No PDF viewer app is available.", Toast.LENGTH_LONG).show();
        }
    }
}
