# Validation script to make it easier to contribute benchmarks to sandmark
import json
from pathlib import Path

HERE = Path(__file__).parent


def validate_config(config_path, tag):
    with open(config_path) as f:
        config = json.load(f)

    errors = []
    benchmarks = [benchmark for benchmark in config["benchmarks"] if tag in benchmark["tags"]]
    names = [benchmark["name"] for benchmark in benchmarks]
    sequential_names = {name for name in names if not name.endswith("_multicore")}
    multicore_names = {name for name in names if name.endswith("_multicore")}
    multicore_names_no_suffix = {name[: -len("_multicore")] for name in multicore_names}

    missing_sequential = multicore_names_no_suffix - sequential_names

    if missing_sequential:
        names = "\n    * ".join(sorted(f"{name}_multicore" for name in missing_sequential))
        error = f"Sequential versions of these benchmarks are missing:\n    * {names}\n"
        errors.append(error)

    bench_map = {benchmark["name"]: benchmark for benchmark in benchmarks}

    for name in multicore_names:
        benchmark = bench_map[name]
        for run in benchmark["runs"]:
            if not (
                run["params"].split()[0].isnumeric()
                or run.get("short_name", "").split("_")[0].isnumeric()
            ):
                error = f"{name}: {run['params']} does not correctly specify the number of domains."
                errors.append(error)

    for name in sequential_names & multicore_names_no_suffix:
        exec_seq = bench_map[name]["executable"]
        exec_par = bench_map[f"{name}_multicore"]["executable"]
        if exec_seq == exec_par:
            error = f"{name}: Parallel version running on 1 domain is not the same as the sequential version."
            errors.append(error)

    if errors:
        errors = "\n  ".join(errors)
        print(f"Errors in '{config_path.name}' with '{tag}' tag:\n  {errors}")

    skipped_benchmarks = {
        benchmark["name"] for benchmark in config["benchmarks"] if tag not in benchmark["tags"]
    }
    if skipped_benchmarks:
        names = "\n  ".join(skipped_benchmarks)
        print(
            f"WARNING: These benchmarks in '{config_path.name}' are not configured to run nightly:\n  {names}"
        )

    if errors or skipped_benchmarks:
        print("#" * 80)

    return not bool(errors)


def main(tag):
    configs = HERE.glob("multicore_*.json")
    valid = True

    for config in configs:
        valid &= validate_config(config, tag=tag)

    if not valid:
        print("See CONTRIBUTING.md for more information on how to fix these errors.")
        exit(1)
    else:
        print("All multicore configuration files are valid.")


if __name__ == "__main__":
    import argparse

    parser = argparse.ArgumentParser()
    parser.add_argument("--tag", type=str, default="macro_bench")
    args = parser.parse_args()
    main(tag=args.tag)
