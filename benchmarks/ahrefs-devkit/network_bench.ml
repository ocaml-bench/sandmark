(** Network GC Benchmark Suite

    This suite stresses the OCaml garbage collector through intensive network
    parsing and manipulation operations. The benchmarks test:
    - IPv4 address parsing (ragel-based parser creating intermediate values)
    - CIDR subnet calculations with bitwise operations
    - Int32 boxing/unboxing patterns
    - String-to-structured data conversions
    - Network address comparisons and transformations *)

open Devkit

(* Benchmark 1: IPv4 Address Parsing Storm *)
let bench_ipv4_parsing_storm () =
  let parsed_ips = ref [] in

  for i = 1 to 10000 do
    let ip_strings =
      [
        Printf.sprintf "%d.%d.%d.%d" (i mod 256)
          (i * 7 mod 256)
          (i * 13 mod 256)
          (i * 17 mod 256);
        Printf.sprintf "192.168.%d.%d" (i mod 256) (i * 3 mod 256);
        Printf.sprintf "10.%d.%d.%d" (i * 5 mod 256) (i * 11 mod 256) (i mod 256);
        Printf.sprintf "172.%d.%d.%d"
          (16 + (i mod 16))
          (i * 2 mod 256)
          (i * 19 mod 256);
      ]
    in

    List.iter
      (fun ip_str ->
        try
          let ip = Network.ipv4_of_string_exn ip_str in
          let str_back = Network.string_of_ipv4 ip in
          let cidr_str = ip_str ^ "/" ^ string_of_int (8 + (i mod 25)) in
          let cidr = Network.cidr_of_string_exn cidr_str in
          let cidr_back = Network.string_of_cidr cidr in

          if i mod 100 = 0 then
            parsed_ips := (ip, cidr, str_back, cidr_back) :: !parsed_ips;

          let _ = Network.ipv4_matches ip cidr in
          ()
        with _ -> ())
      ip_strings;

    if List.length !parsed_ips > 100 then
      parsed_ips := ExtList.List.take 50 !parsed_ips
  done

(* Benchmark 2: CIDR Subnet Calculations *)
let bench_cidr_calculations () =
  let subnet_cache = Hashtbl.create 1000 in

  for i = 1 to 5000 do
    let base_ip =
      Network.ipv4_of_int32 (Int32.of_int (0x0A000000 + (i * 256)))
    in
    let masks = [ 8; 16; 24; 28; 30; 32 ] in

    List.iter
      (fun mask ->
        let cidr_str =
          Printf.sprintf "%s/%d" (Network.string_of_ipv4 base_ip) mask
        in
        let cidr = Network.cidr_of_string_exn cidr_str in
        let net_ip = Network.int32_of_ipv4 (Network.prefix_of_cidr cidr) in
        let net_mask = mask in

        let test_ips =
          List.init 50 (fun j ->
              let offset = Int32.of_int j in
              let test_ip = Int32.add net_ip offset in
              Network.ipv4_of_int32 test_ip)
        in

        let members =
          List.filter (fun ip -> Network.ipv4_matches ip cidr) test_ips
        in

        let member_strings = List.map Network.string_of_ipv4 members in

        if i mod 20 = 0 then
          Hashtbl.replace subnet_cache (i, mask) member_strings;

        let subnet_size = Int32.shift_left 1l (32 - net_mask) in
        let broadcast = Int32.sub (Int32.add net_ip subnet_size) 1l in
        let broadcast_ip = Network.ipv4_of_int32 broadcast in
        let _ = Network.string_of_ipv4 broadcast_ip in
        ())
      masks;

    if i mod 100 = 0 then
      Hashtbl.iter
        (fun (idx, _) _ ->
          if idx < i - 200 then Hashtbl.remove subnet_cache (idx, 0))
        subnet_cache
  done

(* Benchmark 3: Network Range Operations *)
let bench_range_operations () =
  let range_results = ref [] in

  for i = 1 to 2000 do
    let start_ip =
      Network.ipv4_of_int32 (Int32.of_int (0xC0A80000 + (i * 10)))
    in
    let end_ip =
      Network.ipv4_of_int32 (Int32.of_int (0xC0A80000 + (i * 10) + 255))
    in

    let ips_in_range = ref [] in
    let current = ref (Network.int32_of_ipv4 start_ip) in
    let end_val = Network.int32_of_ipv4 end_ip in

    while Int32.compare !current end_val <= 0 do
      let ip = Network.ipv4_of_int32 !current in
      let ip_str = Network.string_of_ipv4 ip in
      ips_in_range := ip_str :: !ips_in_range;
      current := Int32.succ !current
    done;

    let sorted =
      List.sort
        (fun a b ->
          let ip_a = Network.ipv4_of_string_exn a in
          let ip_b = Network.ipv4_of_string_exn b in
          Int32.compare
            (Network.int32_of_ipv4 ip_a)
            (Network.int32_of_ipv4 ip_b))
        !ips_in_range
    in

    let private_ips =
      List.filter
        (fun ip_str ->
          try
            let ip = Network.ipv4_of_string_exn ip_str in
            let ip_val = Network.int32_of_ipv4 ip in
            Int32.logand ip_val 0xFF000000l = 0x0A000000l
            || Int32.logand ip_val 0xFFF00000l = 0xAC100000l
            || Int32.logand ip_val 0xFFFF0000l = 0xC0A80000l
          with _ -> false)
        sorted
    in

    if i mod 50 = 0 then range_results := private_ips @ !range_results;

    if List.length !range_results > 500 then
      range_results := ExtList.List.take 250 !range_results
  done

(* Benchmark 4: Mixed Network Format Parsing *)
let bench_mixed_format_parsing () =
  let parsed_data = ref [] in

  for i = 1 to 3000 do
    let formats =
      [
        Printf.sprintf "%d.%d.%d.%d"
          (i * 7 mod 256)
          (i * 11 mod 256)
          (i * 13 mod 256)
          (i * 17 mod 256);
        Printf.sprintf "%d.%d.%d.%d/%d"
          (i * 3 mod 256)
          (i * 5 mod 256)
          (i * 7 mod 256)
          (i * 9 mod 256)
          (16 + (i mod 17));
        Printf.sprintf "%03d.%03d.%03d.%03d" (i mod 256)
          (i * 2 mod 256)
          (i * 3 mod 256)
          (i * 4 mod 256);
        "0.0.0.0";
        "255.255.255.255";
        "127.0.0.1";
      ]
    in

    List.iter
      (fun format ->
        (try
           let ip = Network.ipv4_of_string_exn format in
           let back = Network.string_of_ipv4 ip in
           let int_val = Network.int32_of_ipv4 ip in
           let from_int = Network.ipv4_of_int32 int_val in
           let final = Network.string_of_ipv4 from_int in

           if i mod 100 = 0 then parsed_data := (back, final) :: !parsed_data
         with _ -> ());

        try
          let cidr = Network.cidr_of_string_exn format in
          let back = Network.string_of_cidr cidr in
          let ip = Network.int32_of_ipv4 (Network.prefix_of_cidr cidr) in
          let mask =
            try
              let slash_pos = String.index format '/' in
              int_of_string
                (String.sub format (slash_pos + 1)
                   (String.length format - slash_pos - 1))
            with _ -> 32
          in

          let network_addr =
            Int32.logand ip
              (Int32.lognot (Int32.sub (Int32.shift_left 1l (32 - mask)) 1l))
          in
          let network_ip = Network.ipv4_of_int32 network_addr in
          let network_str = Network.string_of_ipv4 network_ip in

          if i mod 100 = 0 then
            parsed_data := (back, network_str) :: !parsed_data
        with _ -> ())
      formats;

    if List.length !parsed_data > 200 then
      parsed_data := ExtList.List.take 100 !parsed_data
  done

(* Benchmark 5: Network Address Translation Tables *)
let bench_nat_tables () =
  let nat_table = Hashtbl.create 10000 in
  let reverse_table = Hashtbl.create 10000 in

  for i = 1 to 5000 do
    let internal_ip =
      Network.ipv4_of_string_exn
        (Printf.sprintf "192.168.%d.%d" (i * 3 mod 256) (i mod 256))
    in
    let external_ip =
      Network.ipv4_of_string_exn (Printf.sprintf "203.0.113.%d" (i mod 256))
    in

    for port = 0 to 9 do
      let internal_port = 1024 + (i * 10) + port in
      let external_port = 30000 + (i * 10) + port in

      let internal_addr = (internal_ip, internal_port) in
      let external_addr = (external_ip, external_port) in

      Hashtbl.replace nat_table internal_addr external_addr;
      Hashtbl.replace reverse_table external_addr internal_addr;

      if i mod 10 = 0 then (
        (match Hashtbl.find_opt nat_table internal_addr with
        | Some (ext_ip, ext_port) ->
            let _ = Network.string_of_ipv4 ext_ip in
            let _ = string_of_int ext_port in
            ()
        | None -> ());

        match Hashtbl.find_opt reverse_table external_addr with
        | Some (int_ip, int_port) ->
            let _ = Network.string_of_ipv4 int_ip in
            let _ = string_of_int int_port in
            ()
        | None -> ())
    done;

    if i mod 100 = 0 then (
      let to_remove = ref [] in
      Hashtbl.iter
        (fun k _v ->
          let _ip, port = k in
          if port < 1024 + ((i - 200) * 10) then to_remove := k :: !to_remove)
        nat_table;
      List.iter (Hashtbl.remove nat_table) !to_remove;
      List.iter
        (fun k ->
          match Hashtbl.find_opt nat_table k with
          | Some v -> Hashtbl.remove reverse_table v
          | None -> ())
        !to_remove)
  done

(* Benchmark 6: IP Address Sorting and Comparison *)
let bench_ip_sorting () =
  let sorted_lists = ref [] in

  for i = 1 to 1000 do
    let ip_list =
      List.init 200 (fun j ->
          let idx = (i * 200) + j in
          Printf.sprintf "%d.%d.%d.%d"
            (idx * 7 mod 256)
            (idx * 11 mod 256)
            (idx * 13 mod 256)
            (idx * 17 mod 256))
    in

    let parsed =
      List.map
        (fun s -> try Some (Network.ipv4_of_string_exn s, s) with _ -> None)
        ip_list
      |> List.filter_map (fun x -> x)
    in

    let sorted =
      List.sort
        (fun (ip1, _) (ip2, _) ->
          Int32.compare (Network.int32_of_ipv4 ip1) (Network.int32_of_ipv4 ip2))
        parsed
    in

    let sorted_strings =
      List.map (fun (ip, _) -> Network.string_of_ipv4 ip) sorted
    in

    let grouped = Hashtbl.create 256 in
    List.iter
      (fun (ip, orig) ->
        let subnet = Int32.shift_right (Network.int32_of_ipv4 ip) 8 in
        let existing =
          match Hashtbl.find_opt grouped subnet with Some l -> l | None -> []
        in
        Hashtbl.replace grouped subnet ((ip, orig) :: existing))
      sorted;

    let _max_subnet =
      Hashtbl.fold
        (fun subnet ips (max_sub, max_count) ->
          let count = List.length ips in
          if count > max_count then (subnet, count) else (max_sub, max_count))
        grouped (0l, 0)
    in

    if i mod 50 = 0 then sorted_lists := sorted_strings :: !sorted_lists;

    if List.length !sorted_lists > 20 then
      sorted_lists := ExtList.List.take 10 !sorted_lists
  done

(* Benchmark 7: Broadcast and Network Address Calculations *)
let bench_broadcast_calculations () =
  let boundary_cache = ref [] in

  for i = 1 to 3000 do
    let subnet_sizes = [ 30; 29; 28; 27; 26; 25; 24; 23; 22; 21; 20; 16; 8 ] in

    List.iter
      (fun mask ->
        let base = Int32.of_int (0x0A000000 + (i * 0x10000)) in
        let cidr_str =
          Printf.sprintf "%s/%d"
            (Network.string_of_ipv4 (Network.ipv4_of_int32 base))
            mask
        in

        try
          let cidr = Network.cidr_of_string_exn cidr_str in
          let net_ip = Network.int32_of_ipv4 (Network.prefix_of_cidr cidr) in
          let net_mask = mask in

          let mask_val =
            Int32.lognot (Int32.sub (Int32.shift_left 1l (32 - net_mask)) 1l)
          in
          let network = Int32.logand net_ip mask_val in
          let network_ip = Network.ipv4_of_int32 network in

          let host_bits = 32 - net_mask in
          let broadcast =
            Int32.logor network (Int32.sub (Int32.shift_left 1l host_bits) 1l)
          in
          let broadcast_ip = Network.ipv4_of_int32 broadcast in

          let first_usable =
            if host_bits > 1 then Network.ipv4_of_int32 (Int32.succ network)
            else network_ip
          in
          let last_usable =
            if host_bits > 1 then Network.ipv4_of_int32 (Int32.pred broadcast)
            else broadcast_ip
          in

          let total_hosts =
            if host_bits >= 2 then Int32.sub (Int32.shift_left 1l host_bits) 2l
            else 0l
          in

          let boundaries =
            ( Network.string_of_ipv4 network_ip,
              Network.string_of_ipv4 broadcast_ip,
              Network.string_of_ipv4 first_usable,
              Network.string_of_ipv4 last_usable,
              Int32.to_string total_hosts )
          in

          if i mod 100 = 0 then boundary_cache := boundaries :: !boundary_cache
        with _ -> ())
      subnet_sizes;

    if List.length !boundary_cache > 100 then
      boundary_cache := ExtList.List.take 50 !boundary_cache
  done

(* Benchmark 8: Complex Network Operations *)
let bench_complex_network_ops () =
  let operation_cache = Hashtbl.create 1000 in
  let results = ref [] in

  for i = 1 to 2000 do
    let source_net =
      Network.cidr_of_string_exn (Printf.sprintf "10.%d.0.0/16" (i mod 256))
    in

    let base_ip = Network.int32_of_ipv4 (Network.prefix_of_cidr source_net) in
    let subnets =
      List.init 16 (fun j ->
          let subnet_base = Int32.add base_ip (Int32.of_int (j * 256)) in
          Printf.sprintf "%s/24"
            (Network.string_of_ipv4 (Network.ipv4_of_int32 subnet_base)))
    in

    let valid_subnets =
      List.filter_map
        (fun s ->
          try
            let cidr = Network.cidr_of_string_exn s in
            let sub_ip_obj = Network.prefix_of_cidr cidr in
            if Network.ipv4_matches sub_ip_obj source_net then Some cidr
            else None
          with _ -> None)
        subnets
    in

    let all_ips =
      List.concat_map
        (fun cidr ->
          let net = Network.int32_of_ipv4 (Network.prefix_of_cidr cidr) in
          List.init 10 (fun k ->
              let ip = Int32.add net (Int32.of_int k) in
              Network.ipv4_of_int32 ip))
        valid_subnets
    in

    let ip_strings = List.map Network.string_of_ipv4 all_ips in
    let reparsed =
      List.filter_map
        (fun s -> try Some (Network.ipv4_of_string_exn s) with _ -> None)
        ip_strings
    in

    List.iteri
      (fun j ip ->
        let key = (i, j) in
        let value =
          (ip, List.nth_opt valid_subnets (j mod List.length valid_subnets))
        in
        Hashtbl.replace operation_cache key value)
      reparsed;

    if i mod 10 = 0 then
      for j = 0 to 50 do
        match Hashtbl.find_opt operation_cache (i - 5, j) with
        | Some (ip, Some cidr) ->
            let ip_str = Network.string_of_ipv4 ip in
            let cidr_str = Network.string_of_cidr cidr in
            results := (ip_str, cidr_str) :: !results
        | _ -> ()
      done;

    if i mod 100 = 0 then (
      Hashtbl.iter
        (fun (idx, _) _ ->
          if idx < i - 200 then Hashtbl.remove operation_cache (idx, 0))
        operation_cache;
      if List.length !results > 200 then
        results := ExtList.List.take 100 !results)
  done

(* Main benchmark suite runner *)
let () =
  bench_ipv4_parsing_storm ();
  bench_cidr_calculations ();
  bench_range_operations ();
  bench_mixed_format_parsing ();
  bench_nat_tables ();
  bench_ip_sorting ();
  bench_broadcast_calculations ();
  bench_complex_network_ops ()
