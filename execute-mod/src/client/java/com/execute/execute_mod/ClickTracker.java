package com.execute.execute_mod;

import java.util.ArrayDeque;
import java.util.Queue;

/** Tracks left/right clicks for CPS (clicks per second). */
public class ClickTracker {
    private static final long WINDOW_MS = 1000L;
    private static final Queue<Long> leftClicks = new ArrayDeque<>();
    private static final Queue<Long> rightClicks = new ArrayDeque<>();

    public static void recordLeft() {
        long now = System.currentTimeMillis();
        leftClicks.add(now);
        prune(leftClicks, now);
    }

    public static void recordRight() {
        long now = System.currentTimeMillis();
        rightClicks.add(now);
        prune(rightClicks, now);
    }

    private static void prune(Queue<Long> q, long now) {
        while (!q.isEmpty() && now - q.peek() > WINDOW_MS) q.poll();
    }

    public static int getLeftCPS() {
        prune(leftClicks, System.currentTimeMillis());
        return leftClicks.size();
    }

    public static int getRightCPS() {
        prune(rightClicks, System.currentTimeMillis());
        return rightClicks.size();
    }
}
