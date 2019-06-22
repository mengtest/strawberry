#include "Systems.h"
#include "EntitasPP/Pool.h"

namespace Chestnut {
	namespace Ball {


		Systems::Systems() {
			_indexSystem = RefCountedPtr<IndexSystem>(new IndexSystem());
			_joinSystem = RefCountedPtr<JoinSystem>(new JoinSystem());
		}

		Systems::~Systems() {}

		auto Systems::GetIndexSystem()->RefCountedPtr<IndexSystem> const {
			return _indexSystem;
		}
		
		auto Systems::GetJoinSystem()->RefCountedPtr<JoinSystem> const {
			return _joinSystem;
		}

	}
}