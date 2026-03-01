package com.friendtracker.friend_tracker;

import android.app.Notification;
import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.app.PendingIntent;
import android.app.Service;
import android.content.Intent;
import android.location.Location;
import android.os.Build;
import android.os.IBinder;
import android.os.Looper;

import androidx.annotation.Nullable;
import androidx.core.app.NotificationCompat;

import com.google.android.gms.location.FusedLocationProviderClient;
import com.google.android.gms.location.LocationCallback;
import com.google.android.gms.location.LocationRequest;
import com.google.android.gms.location.LocationResult;
import com.google.android.gms.location.LocationServices;
import com.google.android.gms.location.Priority;

/**
 * Java foreground service that streams GPS updates to Flutter via a
 * static callback. Flutter registers the callback through the
 * LocationChannelHandler platform channel.
 */
public class LocationForegroundService extends Service {

    public static final String CHANNEL_ID = "friend_tracker_location";
    public static final String ACTION_START = "START_TRACKING";
    public static final String ACTION_STOP = "STOP_TRACKING";

    private static final int NOTIFICATION_ID = 1001;
    private static final long UPDATE_INTERVAL_MS = 10_000L;   // 10 s
    private static final long FASTEST_INTERVAL_MS = 5_000L;   //  5 s

    private FusedLocationProviderClient fusedClient;
    private LocationCallback locationCallback;

    /** Called by Flutter to receive location updates. */
    public interface LocationListener {
        void onLocationUpdate(double latitude, double longitude, float accuracy);
    }

    private static LocationListener sListener;

    public static void setLocationListener(LocationListener listener) {
        sListener = listener;
    }

    @Override
    public void onCreate() {
        super.onCreate();
        fusedClient = LocationServices.getFusedLocationProviderClient(this);
        locationCallback = new LocationCallback() {
            @Override
            public void onLocationResult(LocationResult result) {
                Location loc = result.getLastLocation();
                if (loc != null && sListener != null) {
                    sListener.onLocationUpdate(
                            loc.getLatitude(),
                            loc.getLongitude(),
                            loc.getAccuracy()
                    );
                }
            }
        };
        createNotificationChannel();
    }

    @Override
    public int onStartCommand(Intent intent, int flags, int startId) {
        if (intent != null && ACTION_STOP.equals(intent.getAction())) {
            stopSelf();
            return START_NOT_STICKY;
        }

        startForeground(NOTIFICATION_ID, buildNotification());
        requestLocationUpdates();
        return START_STICKY;
    }

    @SuppressWarnings("MissingPermission")
    private void requestLocationUpdates() {
        LocationRequest request = new LocationRequest.Builder(UPDATE_INTERVAL_MS)
                .setPriority(Priority.PRIORITY_HIGH_ACCURACY)
                .setMinUpdateIntervalMillis(FASTEST_INTERVAL_MS)
                .build();

        fusedClient.requestLocationUpdates(
                request,
                locationCallback,
                Looper.getMainLooper()
        );
    }

    @Override
    public void onDestroy() {
        super.onDestroy();
        fusedClient.removeLocationUpdates(locationCallback);
    }

    @Nullable
    @Override
    public IBinder onBind(Intent intent) {
        return null;
    }

    private void createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            NotificationChannel channel = new NotificationChannel(
                    CHANNEL_ID,
                    "Location Tracking",
                    NotificationManager.IMPORTANCE_LOW
            );
            channel.setDescription("Shares your location with friends");
            NotificationManager manager = getSystemService(NotificationManager.class);
            if (manager != null) manager.createNotificationChannel(channel);
        }
    }

    private Notification buildNotification() {
        Intent stopIntent = new Intent(this, LocationForegroundService.class);
        stopIntent.setAction(ACTION_STOP);
        PendingIntent stopPending = PendingIntent.getService(
                this, 0, stopIntent,
                PendingIntent.FLAG_UPDATE_CURRENT | PendingIntent.FLAG_IMMUTABLE
        );

        Intent launchIntent = getPackageManager()
                .getLaunchIntentForPackage(getPackageName());
        PendingIntent contentPending = PendingIntent.getActivity(
                this, 0, launchIntent,
                PendingIntent.FLAG_UPDATE_CURRENT | PendingIntent.FLAG_IMMUTABLE
        );

        return new NotificationCompat.Builder(this, CHANNEL_ID)
                .setContentTitle("Friend Tracker")
                .setContentText("Sharing your location with friends")
                .setSmallIcon(android.R.drawable.ic_menu_mylocation)
                .setOngoing(true)
                .setContentIntent(contentPending)
                .addAction(android.R.drawable.ic_delete, "Stop", stopPending)
                .build();
    }
}
