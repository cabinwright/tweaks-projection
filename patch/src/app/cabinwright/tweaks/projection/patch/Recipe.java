/*
 * Part of projpatch (tweaks.projection), AGPL-3.0-or-later, Copyright (c) 2026 hazptr.
 * A Java version of the recipe check/apply of HMG Leafia Plus's lpatch (tools/lpatch/lpatch.c,
 * GPL-3.0-or-later, https://github.com/VysseCodes/HMG-Leafia-Plus).
 */
package app.cabinwright.tweaks.projection.patch;

import java.io.File;
import java.io.IOException;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;

/**
 * HMG Leafia Plus byte recipes (recipes/README.md there), with the same rules and output as
 * its lpatch (tools/lpatch/lpatch.c, check and apply). A recipe holds no bytes of the file it
 * patches: only md5s of regions around each change, before and after, and the new bytes.
 *
 *   id <name>
 *   file <path on the head unit>
 *   native <md5> [note]                       a file that already has the feature
 *   verify <hex offset> <length> <md5 before> <md5 after>
 *   patch <hex offset> <new bytes, hex>       must sit inside a verify region
 *
 * Status of a file: PATCHABLE (every region original), APPLIED (every region patched),
 * NATIVE (whole-file md5 on a native line), MISMATCH (anything else), MISSING.
 */
final class Recipe {
    static final String[] NAMES = {"PATCHABLE", "APPLIED", "NATIVE", "MISMATCH"};
    static final int PATCHABLE = 0, APPLIED = 1, NATIVE = 2, MISMATCH = 3;

    String id = "?";
    final List<String> natives = new ArrayList<String>();
    final List<long[]> verify = new ArrayList<long[]>();      // offset, length
    final List<String[]> sums = new ArrayList<String[]>();    // before, after
    final List<Long> patchAt = new ArrayList<Long>();
    final List<byte[]> patchBytes = new ArrayList<byte[]>();

    private Recipe() {
    }

    static Recipe load(File f) throws Exception {
        Recipe r = new Recipe();
        for (String raw : new String(Main.read(f), "UTF-8").split("\n")) {
            String line = raw;
            int hash = line.indexOf('#');
            if (hash >= 0) line = line.substring(0, hash);
            String[] t = line.trim().split("[ \t]+");
            if (t.length == 0 || t[0].isEmpty()) continue;
            if (t[0].equals("id") && t.length >= 2) {
                r.id = t[1];
            } else if (t[0].equals("native") && t.length >= 2) {
                r.natives.add(md5(t[1]));
            } else if (t[0].equals("verify") && t.length >= 5) {
                long len = Long.parseLong(t[2]);
                if (len <= 0) throw new IOException("verify length 0");
                r.verify.add(new long[] {hex(t[1]), len});
                r.sums.add(new String[] {md5(t[3]), md5(t[4])});
            } else if (t[0].equals("patch") && t.length >= 3) {
                byte[] b = bytes(t[2]);
                if (b.length == 0) throw new IOException("empty patch");
                r.patchAt.add(hex(t[1]));
                r.patchBytes.add(b);
            }
        }
        if (r.patchAt.isEmpty() && r.natives.isEmpty()) throw new IOException("recipe has no patch or native lines");
        if (!r.patchAt.isEmpty() && r.verify.isEmpty()) throw new IOException("recipe has patches but no verify lines");
        // every patched byte inside a verified region
        for (int i = 0; i < r.patchAt.size(); i++) {
            long a = r.patchAt.get(i), b = a + r.patchBytes.get(i).length;
            boolean ok = false;
            for (long[] v : r.verify) {
                if (a >= v[0] && b <= v[0] + v[1]) ok = true;
            }
            if (!ok) throw new IOException("patch outside every verify region");
        }
        return r;
    }

    int classify(byte[] f, StringBuilder spots) throws Exception {
        String whole = Main.hex(Main.md5(f));
        if (natives.contains(whole)) return NATIVE;
        int before = 0, after = 0;
        for (int i = 0; i < verify.size(); i++) {
            long off = verify.get(i)[0], len = verify.get(i)[1];
            boolean in = off + len <= f.length;
            String h = in ? Main.hex(Main.md5(Arrays.copyOfRange(f, (int) off, (int) (off + len)))) : "";
            boolean b = in && h.equals(sums.get(i)[0]), a = in && h.equals(sums.get(i)[1]);
            if (b) before++;
            if (a) after++;
            if (spots != null) {
                spots.append("SPOT ").append(id).append(" off=0x").append(Long.toHexString(off)).append(" len=").append(len)
                        .append(b ? " status=original" : a ? " status=patched" : in ? " status=other md5=" + h : " status=outside")
                        .append('\n');
            }
        }
        if (!verify.isEmpty() && before == verify.size()) return PATCHABLE;
        if (!verify.isEmpty() && after == verify.size()) return APPLIED;
        return MISMATCH;
    }

    /** Prints the SPOT and RESULT lines; false for MISMATCH or MISSING. */
    static boolean check(File recipe, File file) throws Exception {
        Recipe r = load(recipe);
        if (!file.isFile()) {
            System.out.println("RESULT " + r.id + " status=MISSING file=" + file);
            return false;
        }
        byte[] f = Main.read(file);
        StringBuilder spots = new StringBuilder();
        int st = r.classify(f, spots);
        System.out.print(spots);
        System.out.println("RESULT " + r.id + " status=" + NAMES[st] + " file=" + file + " size=" + f.length
                + " md5=" + Main.hex(Main.md5(f)));
        return st != MISMATCH;
    }

    static void apply(File recipe, File src, File dst) throws Exception {
        Recipe r = load(recipe);
        byte[] f = Main.read(src);
        int st = r.classify(f, null);
        if (st != PATCHABLE) throw new IOException("not applying, " + src + " is " + NAMES[st]);
        for (int i = 0; i < r.patchAt.size(); i++) {
            byte[] b = r.patchBytes.get(i);
            System.arraycopy(b, 0, f, (int) (long) r.patchAt.get(i), b.length);
        }
        if (r.classify(f, null) != APPLIED) throw new IOException("patch did not verify");
        Main.write(dst, f);
        if (r.classify(Main.read(dst), null) != APPLIED) throw new IOException("written file did not verify");
        System.out.println("applied " + r.id + " -> " + dst);
    }

    private static long hex(String s) {
        if (s.startsWith("0x") || s.startsWith("0X")) s = s.substring(2);
        return Long.parseLong(s, 16);
    }

    private static String md5(String s) throws IOException {
        if (!s.matches("[0-9a-fA-F]{32}")) throw new IOException("bad md5 in recipe: " + s);
        return s.toLowerCase();
    }

    private static byte[] bytes(String s) throws IOException {
        if (s.length() % 2 != 0) throw new IOException("odd hex length in recipe");
        byte[] b = new byte[s.length() / 2];
        for (int i = 0; i < b.length; i++) {
            int hi = Character.digit(s.charAt(2 * i), 16), lo = Character.digit(s.charAt(2 * i + 1), 16);
            if (hi < 0 || lo < 0) throw new IOException("bad hex in recipe");
            b[i] = (byte) (hi * 16 + lo);
        }
        return b;
    }
}
