/*
 * Copyright 2016-2018 JD Fergason
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

/**
    Abstraction for TOML key paths
*/
public struct Path: Hashable, Equatable {
    internal(set) public var components: [String]

    init(_ components: [String]) {
        self.components = components
    }

    func begins(with: [String]) -> Bool {
        if with.count > components.count {
            return false
        }

        for x in with.indices {
            if components[x] != with[x] {
                return false
            }
        }

        return true
    }

    public var hashValue: Int {
        return components.reduce(0, { $0 ^ $1.hashValue })
    }

    public static func == (lhs: Path, rhs: Path) -> Bool {
        return lhs.components == rhs.components
    }

    static func + (lhs: Path, rhs: Path) -> Path {
        return Path(lhs.components + rhs.components)
    }
}
